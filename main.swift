import Cocoa
import CoreText

let bitcoinOrange = NSColor(calibratedRed: 1, green: 0.36, blue: 0.06, alpha: 1)

let arcadeColors = [
    NSColor(calibratedRed: 1, green: 0.15, blue: 0.06, alpha: 1),
    NSColor(calibratedRed: 1, green: 0.40, blue: 0.02, alpha: 1),
    NSColor(calibratedRed: 1, green: 0.80, blue: 0.02, alpha: 1),
    NSColor(calibratedRed: 0.72, green: 0.98, blue: 0.10, alpha: 1)
]

class DrawingLabel: NSTextField {
    override var isFlipped: Bool { false }
    override func draw(_ dirtyRect: NSRect) {
        attributedStringValue.draw(at: .zero)
    }
}

final class PriceField: DrawingLabel {
    var arcade = false { didSet { needsDisplay = true } }
    override func draw(_ dirtyRect: NSRect) {
        guard arcade else { super.draw(dirtyRect); return }
        let context = NSGraphicsContext.current!.cgContext
        context.beginTransparencyLayer(auxiliaryInfo: nil)
        super.draw(dirtyRect)
        context.setBlendMode(.sourceIn)
        NSGradient(colors: arcadeColors)!.draw(in: NSRect(x: 0, y: 0, width: max(1, min(bounds.width, attributedStringValue.size().width)), height: bounds.height), angle: 0)
        context.endTransparencyLayer()
    }
}

final class RetroBackground: NSView {
    var arcade = false {
        didSet {
            if oldValue != arcade {
                for i in particles.indices {
                    particles[i].x = .random(in: 0...max(bounds.width, 1))
                    particles[i].y = .random(in: 0...max(bounds.height, 1))
                }
            }
            needsDisplay = true
        }
    }
    var hoverChanged: ((Bool) -> Void)?
    private var hoverArea: NSTrackingArea?

    private struct Particle {
        var x: CGFloat
        var y: CGFloat
        var dx: CGFloat
        var dy: CGFloat
        let radius: CGFloat
        let spark: Bool
    }
    private var particles: [Particle] = (0..<110).map { i in
        Particle(x: .random(in: 0...320), y: .random(in: 0...120),
                 dx: .random(in: -0.14...0.14), dy: .random(in: 0.05...0.18),
                 radius: .random(in: 0.55...1.1), spark: i % 12 == 0)
    }
    private var animationTimer: Timer?
    private var observers: [NSObjectProtocol] = []

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
        observers.removeAll()
        guard let window = window else { stopAnimation(); return }
        observers.append(NotificationCenter.default.addObserver(
            forName: NSWindow.didChangeOcclusionStateNotification, object: window, queue: .main
        ) { [weak self] _ in self?.resumeAnimation() })
        observers.append(NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification, object: window, queue: .main
        ) { [weak self] _ in self?.stopAnimation() })
        resumeAnimation()
    }

    func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    func resumeAnimation() {
        guard let window = window, window.isVisible,
              window.occlusionState.contains(.visible),
              !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
            stopAnimation()
            return
        }
        guard animationTimer == nil else { return }
        let timer = Timer(timeInterval: 1.0 / 30, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            guard let window = self.window, window.isVisible,
                  window.occlusionState.contains(.visible),
                  !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
                self.stopAnimation()
                return
            }
            for i in self.particles.indices {
                if self.arcade {
                    let cx = self.bounds.width * 0.55, cy = self.bounds.height * 0.5
                    var dx = self.particles[i].x - cx, dy = self.particles[i].y - cy
                    if hypot(dx, dy) < 8 || self.particles[i].x < -20 || self.particles[i].x > self.bounds.width + 20 || self.particles[i].y < -20 || self.particles[i].y > self.bounds.height + 20 {
                        let angle = CGFloat.random(in: 0...(2 * .pi))
                        dx = cos(angle) * 9; dy = sin(angle) * 9
                        self.particles[i].x = cx + dx
                        self.particles[i].y = cy + dy
                    }
                    self.particles[i].x += dx * 0.018
                    self.particles[i].y += dy * 0.018
                    continue
                }
                self.particles[i].x += self.particles[i].dx
                self.particles[i].y += self.particles[i].dy
                if self.particles[i].x < 0 || self.particles[i].x > self.bounds.width {
                    self.particles[i].dx *= -1
                    self.particles[i].x = min(max(0, self.particles[i].x), self.bounds.width)
                }
                if self.particles[i].y < 0 || self.particles[i].y > self.bounds.height {
                    self.particles[i].dy *= -1
                    self.particles[i].y = min(max(0, self.particles[i].y), self.bounds.height)
                }
            }
            self.needsDisplay = true
        }
        timer.tolerance = 0.008
        animationTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    deinit {
        animationTimer?.invalidate()
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let hoverArea = hoverArea { removeTrackingArea(hoverArea) }
        let area = NSTrackingArea(rect: .zero,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
            owner: self, userInfo: nil)
        addTrackingArea(area)
        hoverArea = area
        if let window = window {
            let point = convert(window.mouseLocationOutsideOfEventStream, from: nil)
            hoverChanged?(bounds.contains(point))
        }
    }

    override func mouseMoved(with event: NSEvent) { hoverChanged?(true) }
    override func mouseEntered(with event: NSEvent) { hoverChanged?(true) }
    override func mouseExited(with event: NSEvent) { hoverChanged?(false) }

    override func draw(_ dirtyRect: NSRect) {
        NSColor(white: 0.045, alpha: 1).setFill()
        bounds.fill()
        for particle in particles {
            if arcade {
                let dx = particle.x - bounds.width * 0.55
                let dy = particle.y - bounds.height * 0.5
                let distance = max(hypot(dx, dy), 1)
                let length = 2 + min(distance / 160, 1) * 16
                let behindText = particle.x < bounds.width * 0.62 && particle.y > 32 && particle.y < 95
                NSColor(white: 0.95, alpha: behindText ? 0.10 : (particle.spark ? 0.55 : 0.3)).setStroke()
                let line = NSBezierPath()
                line.move(to: NSPoint(x: particle.x, y: particle.y))
                line.line(to: NSPoint(x: particle.x + dx / distance * length, y: particle.y + dy / distance * length))
                line.lineWidth = particle.spark ? 1 : 0.5
                line.stroke()
            } else {
                NSColor(white: 1, alpha: particle.spark ? 0.55 : 0.32).setFill()
                NSBezierPath(ovalIn: NSRect(x: particle.x - particle.radius,
                    y: particle.y - particle.radius, width: particle.radius * 2,
                    height: particle.radius * 2)).fill()
            }
        }
    }
}

final class SparklineView: NSView {
    var arcade = false { didSet { needsDisplay = true } }
    private var samples: [Double] = []

    func append(_ price: Double) {
        samples.append(price)
        if samples.count > 120 { samples.removeFirst(samples.count - 120) }
        setAccessibilityLabel("Bitcoin price trend, current session, \(samples.count) readings")
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let minimum = samples.min(), let maximum = samples.max() else { return }
        let area = bounds.insetBy(dx: 3, dy: 4)
        let spread = max(maximum - minimum, maximum * 0.0001)
        let middle = (maximum + minimum) / 2
        func point(_ i: Int) -> NSPoint {
            let x = area.minX + CGFloat(i) / CGFloat(max(samples.count - 1, 1)) * area.width
            let y = area.midY + CGFloat((samples[i] - middle) / spread) * area.height * 0.8
            return NSPoint(x: x, y: arcade ? (y / 2).rounded() * 2 : y)
        }
        if samples.count > 1 {
            let line = NSBezierPath()
            line.move(to: point(0))
            for i in 1..<samples.count {
                if arcade { line.line(to: NSPoint(x: point(i).x, y: point(i - 1).y)) }
                line.line(to: point(i))
            }
            line.lineWidth = arcade ? 2.0 : 1.2
            line.lineJoinStyle = arcade ? .miter : .round
            line.lineCapStyle = arcade ? .butt : .round
            bitcoinOrange.withAlphaComponent(0.8).setStroke()
            if arcade {
                let context = NSGraphicsContext.current!.cgContext
                context.beginTransparencyLayer(auxiliaryInfo: nil)
                NSColor.white.setStroke()
                line.stroke()
                context.setBlendMode(.sourceIn)
                NSGradient(colors: [bitcoinOrange, NSColor(calibratedRed: 1, green: 0.75, blue: 0.08, alpha: 1)])!.draw(in: bounds, angle: 0)
                context.endTransparencyLayer()
            } else { line.stroke() }
        }
        let last = point(samples.count - 1)
        (arcade ? NSColor(calibratedRed: 1, green: 0.75, blue: 0.08, alpha: 1) : bitcoinOrange).setFill()
        NSBezierPath(ovalIn: NSRect(x: last.x - 1.7, y: last.y - 1.7, width: 3.4, height: 3.4)).fill()
    }
}

struct Quote: Decodable {
    struct Data: Decodable { let amount: String; let currency: String }
    let data: Data
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var statusItem: NSStatusItem!
    var menuPriceItem: NSMenuItem!
    var menuPriceText = "…"
    var showsMenuPrice: Bool {
        UserDefaults.standard.object(forKey: "ShowMenuBarPrice") as? Bool ?? true
    }
    var arcade: Bool { UserDefaults.standard.string(forKey: "WidgetStyle") != "classic" }
    var styleItems: [NSMenuItem] = []
    var contentStack: NSStackView?
    var headingView: NSView?
    var formattedPrice: String?
    let title = DrawingLabel(labelWithString: "BITCOIN")
    var timer: Timer?
    var loading = false
    var lastUpdated: Date?
    let sparkline = SparklineView()
    let price = PriceField(labelWithString: "—")
    let detail = DrawingLabel(labelWithString: "Fetching BTC / USD")
    let refresh = NSButton(title: "Refresh", target: nil, action: nil)

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let fontURL = Bundle.main.url(forResource: "Silkscreen-Regular", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        }
        NSApp.setActivationPolicy(.accessory)
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 320, height: 136),
                          styleMask: [.titled, .closable, .fullSizeContentView],
                          backing: .buffered, defer: false)
        window.title = "Bitcoin Voyager"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.acceptsMouseMovedEvents = true
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.setFrameAutosaveName("BitcoinWidgetPosition")
        if !window.setFrameUsingName("BitcoinWidgetPosition") { window.center() }
        window.setContentSize(NSSize(width: 320, height: 136))
        window.appearance = NSAppearance(named: .darkAqua)
        let background = RetroBackground()
        window.contentView = background
        title.font = .monospacedSystemFont(ofSize: 11, weight: .medium)
        title.textColor = bitcoinOrange.withAlphaComponent(0.9)
        price.font = NSFont.monospacedSystemFont(ofSize: 32, weight: .light)
        price.textColor = bitcoinOrange
        detail.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        detail.textColor = NSColor(white: 0.5, alpha: 1)
        refresh.title = ""
        refresh.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: "Refresh price")
        refresh.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        refresh.wantsLayer = true
        refresh.alphaValue = 0
        background.hoverChanged = { [weak self] hovered in
            guard let self = self else { return }
            if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
                self.refresh.alphaValue = hovered ? 1 : 0
            } else {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = hovered ? 0.22 : 0.18
                    self.refresh.animator().alphaValue = hovered ? 1 : 0
                }
            }
        }
        refresh.imagePosition = .imageOnly
        refresh.isBordered = false
        refresh.contentTintColor = NSColor(white: 0.5, alpha: 1)
        refresh.toolTip = "Refresh price"
        refresh.setAccessibilityLabel("Refresh price")
        refresh.target = self
        refresh.action = #selector(refreshNow)
        for view in [title, price, detail, refresh, sparkline] {
            view.translatesAutoresizingMaskIntoConstraints = false
            background.addSubview(view)
        }
        sparkline.toolTip = "Live price trend · this session · up to 60 minutes"
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 20),
            title.topAnchor.constraint(equalTo: background.topAnchor, constant: 37),
            title.heightAnchor.constraint(equalToConstant: 16),
            title.widthAnchor.constraint(equalToConstant: 150),
            price.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 20),
            price.topAnchor.constraint(equalTo: background.topAnchor, constant: 48),
            price.heightAnchor.constraint(equalToConstant: 44),
            price.widthAnchor.constraint(equalToConstant: 194),
            detail.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 20),
            detail.topAnchor.constraint(equalTo: background.topAnchor, constant: 93),
            detail.heightAnchor.constraint(equalToConstant: 16),
            refresh.leadingAnchor.constraint(equalTo: detail.trailingAnchor, constant: 3),
            refresh.centerYAnchor.constraint(equalTo: detail.centerYAnchor, constant: 1),
            refresh.widthAnchor.constraint(equalToConstant: 18),
            refresh.heightAnchor.constraint(equalToConstant: 18),
            sparkline.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -18),
            sparkline.topAnchor.constraint(equalTo: background.topAnchor, constant: 58),
            sparkline.widthAnchor.constraint(equalToConstant: 84),
            sparkline.heightAnchor.constraint(equalToConstant: 26)
        ])
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let menuIcon = NSImage(size: NSSize(width: 16, height: 14), flipped: false) { imageRect in
            let rect = NSRect(x: 0, y: 0, width: 14, height: imageRect.height)
            NSColor.black.setFill()
            NSBezierPath(ovalIn: rect.insetBy(dx: 0.25, dy: 0.25)).fill()
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current?.cgContext.setBlendMode(.destinationOut)
            let text = "₿" as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: NSColor.white
            ]
            let size = text.size(withAttributes: attributes)
            text.draw(at: NSPoint(x: (rect.width - size.width) / 2,
                                  y: (rect.height - size.height) / 2), withAttributes: attributes)
            NSGraphicsContext.restoreGraphicsState()
            return true
        }
        menuIcon.isTemplate = true
        statusItem.button?.image = menuIcon
        statusItem.button?.imagePosition = .imageLeading
        statusItem.button?.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        statusItem.button?.title = "…"
        let menu = NSMenu()
        menu.addItem(withTitle: "Show Bitcoin Voyager", action: #selector(showWidget), keyEquivalent: "")
        menu.addItem(withTitle: "Refresh Price", action: #selector(refreshNow), keyEquivalent: "r")
        menuPriceItem = menu.addItem(withTitle: "Show Price in Menu Bar", action: #selector(toggleMenuPrice), keyEquivalent: "")
        let styleMenu = NSMenu(title: "Style")
        for (index, name) in ["Classic", "Arcade"].enumerated() {
            let item = styleMenu.addItem(withTitle: name, action: #selector(selectStyle(_:)), keyEquivalent: index == 0 ? "1" : "2")
            item.tag = index
            item.target = self
            styleItems.append(item)
        }
        let styleEntry = menu.addItem(withTitle: "Style", action: nil, keyEquivalent: "")
        styleEntry.submenu = styleMenu
        let mainMenu = NSMenu()
        let styles = mainMenu.addItem(withTitle: "Style", action: nil, keyEquivalent: "")
        styles.submenu = styleMenu.copy() as? NSMenu
        NSApp.mainMenu = mainMenu
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Bitcoin Voyager", action: #selector(quit), keyEquivalent: "q")
        for item in menu.items { item.target = self }
        statusItem.menu = menu
        updateMenuPrice()
        applyStyle()
        showWidget()
        refreshNow()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in self?.refreshNow() }
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(refreshNow), name: NSWorkspace.didWakeNotification, object: nil)
    }

    @objc func selectStyle(_ sender: NSMenuItem) {
        UserDefaults.standard.set(sender.tag == 1 ? "arcade" : "classic", forKey: "WidgetStyle")
        applyStyle()
    }

    func applyStyle() {
        for item in styleItems { item.state = (item.tag == (arcade ? 1 : 0)) ? .on : .off }
        (window.contentView as? RetroBackground)?.arcade = arcade
        sparkline.arcade = arcade
        price.arcade = arcade
        title.font = arcade ? NSFont(name: "Silkscreen-Regular", size: 10.5) : .monospacedSystemFont(ofSize: 11, weight: .medium)
        title.textColor = arcade ? NSColor(white: 0.6, alpha: 1) : bitcoinOrange
        detail.font = arcade ? NSFont(name: "Silkscreen-Regular", size: 10.5) : .monospacedSystemFont(ofSize: 10, weight: .regular)
        if let date = lastUpdated, !detail.stringValue.contains("Stale") {
            detail.stringValue = "\(arcade ? "UPDATED" : "Updated") \(timeString(date))"
        }
        detail.textColor = arcade ? NSColor(white: 0.6, alpha: 1) : NSColor(white: 0.5, alpha: 1)
        refresh.contentTintColor = detail.textColor
        if let heading = headingView { contentStack?.setCustomSpacing(arcade ? 5 : 3, after: heading) }
        renderPrice()
    }

    func renderPrice() {
        guard let formatted = formattedPrice else { return }
        let text = arcade ? formatted.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "") : formatted
        let font = arcade ? (NSFont(name: "Silkscreen-Regular", size: 34) ?? .monospacedSystemFont(ofSize: 34, weight: .regular)) : .monospacedSystemFont(ofSize: 32, weight: .light)
        let attributed = NSMutableAttributedString(string: text, attributes: [
            .font: font, .foregroundColor: arcade ? NSColor.white : bitcoinOrange, .kern: arcade ? -1.0 : -2.0
        ])
        if !arcade {
            attributed.addAttribute(.kern, value: 0.0, range: NSRange(location: 0, length: 1))
            let comma = (text as NSString).range(of: ",")
            if comma.location != NSNotFound {
                attributed.addAttribute(.kern, value: -5.0, range: comma)
                if comma.location > 0 { attributed.addAttribute(.kern, value: -5.0, range: NSRange(location: comma.location - 1, length: 1)) }
            }
        }
        price.attributedStringValue = attributed
        price.invalidateIntrinsicContentSize()
        price.needsDisplay = true
    }

    @objc func toggleMenuPrice() {
        UserDefaults.standard.set(!showsMenuPrice, forKey: "ShowMenuBarPrice")
        updateMenuPrice()
    }

    func updateMenuPrice() {
        menuPriceItem?.state = showsMenuPrice ? .on : .off
        statusItem.button?.attributedTitle = NSAttributedString(
            string: showsMenuPrice ? menuPriceText : "",
            attributes: [.font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular), .kern: -0.35])
        statusItem.button?.imagePosition = showsMenuPrice ? .imageLeading : .imageOnly
        statusItem.button?.toolTip = "Bitcoin Voyager"
    }

    @objc func showWidget() {
        window.makeKeyAndOrderFront(nil)
        (window.contentView as? RetroBackground)?.resumeAnimation()
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func refreshNow() {
        guard !loading else { return }
        loading = true
        refresh.isEnabled = false
        detail.stringValue = lastUpdated == nil ? "Fetching BTC / USD…" : "Updating…"
        var request = URLRequest(url: URL(string: "https://api.coinbase.com/v2/prices/BTC-USD/spot")!)
        request.timeoutInterval = 15
        request.cachePolicy = .reloadIgnoringLocalCacheData
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            var value: Double?
            if error == nil, let response = response as? HTTPURLResponse,
               (200..<300).contains(response.statusCode), let data = data,
               let quote = try? JSONDecoder().decode(Quote.self, from: data),
               quote.data.currency == "USD", let amount = Double(quote.data.amount), amount.isFinite, amount > 0 {
                value = amount
            }
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.loading = false
                self.refresh.isEnabled = true
                if let value = value {
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .currency
                    formatter.currencyCode = "USD"
                    formatter.minimumFractionDigits = 0
                    formatter.maximumFractionDigits = 0
                    formatter.locale = Locale(identifier: "en_US")
                    let formatted = formatter.string(from: NSNumber(value: value)) ?? "—"
                    self.formattedPrice = formatted
                    self.renderPrice()
                    self.menuPriceText = formatted
                    self.updateMenuPrice()
                    self.sparkline.append(value)
                    self.lastUpdated = Date()
                    self.detail.stringValue = "\(self.arcade ? "UPDATED" : "Updated") \(self.timeString(self.lastUpdated!))"
                    self.detail.textColor = self.arcade ? NSColor(white: 0.6, alpha: 1) : NSColor(white: 0.5, alpha: 1)
                } else {
                    self.detail.textColor = bitcoinOrange
                    if let date = self.lastUpdated {
                        self.detail.stringValue = "Stale · last updated \(self.timeString(date))"
                    } else {
                        self.price.stringValue = "Unavailable"
                        self.price.font = .systemFont(ofSize: 20, weight: .light)
                        self.detail.stringValue = "Couldn’t connect · retrying every 30s"
                    }
                    self.menuPriceText = "⚠"
                    self.updateMenuPrice()
                }

            }
        }.resume()
    }

    func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }

    @objc func quit() { NSApp.terminate(nil) }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
