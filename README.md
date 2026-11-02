# Bitcoin Voyager

A Bitcoin price widget for your Mac. It hangs out on your desktop, keeps an eye on the price, and has two moods: Classic and Arcade.

## Pick your mood

**Classic** is the quieter one. Orange monospace numbers, a drifting starfield, and a simple line chart.

**Arcade** is more playful. Pixel type, a red-to-orange-to-yellow-green price gradient, a chunky stepped chart, and stars moving past like you're in hyperspace.

Switch between them from **Style** in the menu bar. The app remembers your choice.

## The useful stuff

- Bitcoin's spot price in USD, refreshed every 30 seconds while your Mac is awake.
- Whole dollars. No cents.
- A small chart beside the price that builds as the app runs.
- An optional menu bar price. If the widget is enough, turn off **Show Price in Menu Bar** and keep just the icon.
- A refresh button that fades in on hover.
- A draggable window that remembers where you put it.

The chart starts as a dot and becomes a line after another successful price reading. It keeps the latest 120 readings—roughly an hour with automatic updates—and starts fresh when you quit. It isn't a historical 24-hour chart.

If a request fails, the last price stays visible with a stale timestamp. Background animation pauses when the window is hidden or covered and respects macOS Reduce Motion.

## Run it

This is a standalone Mac app with a floating window. It doesn't appear in Apple's Edit Widgets gallery.

To build it yourself, you'll need a Mac and Apple's command line developer tools. Clone or download this project, then run this in its folder:

```sh
bash build.sh
```

Double-click **Bitcoin Voyager.app** when the build finishes. The build is made for the Mac you're building on.

Closing the window keeps the menu bar companion running. Use **Show Bitcoin Voyager** to bring it back or **Quit Bitcoin Voyager** to exit. It doesn't automatically launch at login.

With the widget focused, **Command-1** switches to Classic and **Command-2** switches to Arcade.

## A few notes

Prices come from [Coinbase's public BTC/USD spot-price endpoint](https://api.coinbase.com/v2/prices/BTC-USD/spot). No account or API key needed.

Built with Swift and AppKit. Arcade uses [Silkscreen](https://fonts.google.com/specimen/Silkscreen). The icon is a custom mark based on Major Mono Display. Bundled font licenses are in `Resources`.

This is an early personal project, tested on the Mac it was built on. The build script signs the app locally; it isn't Developer ID signed or notarized for public distribution yet.

## License

[MIT](LICENSE). Copyright © 2026 Bitcoin Voyager contributors.

Bundled font files retain their SIL Open Font License; see the license files in `Resources`.
