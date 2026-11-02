#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
APP="$(pwd)/Bitcoin Voyager.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Resources/Silkscreen-Regular.ttf Resources/Silkscreen-OFL.txt Resources/MenuIcon.png Resources/AppIcon.icns Resources/SpaceMono-Regular.ttf Resources/SpaceMono-OFL.txt "$APP/Contents/Resources/"
swiftc main.swift -o "$APP/Contents/MacOS/BitcoinWidget" -framework Cocoa -module-cache-path /private/tmp/bitcoin-widget-module-cache
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>BitcoinWidget</string>
<key>CFBundleIdentifier</key><string>local.bitcoin.desktopwidget</string>
<key>CFBundleName</key><string>Bitcoin Voyager</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundleDisplayName</key><string>Bitcoin Voyager</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>12.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$APP"
printf 'Built: %s\n' "$APP"
