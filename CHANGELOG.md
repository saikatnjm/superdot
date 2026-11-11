# Changelog

All notable changes to SuperDot. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-11-11

### Added
- Emoji panel on <kbd>Super</kbd> + <kbd>.</kbd>, like Win+. on Windows: Emoji, Kaomoji and Symbols tabs.
- Picking an item types it into the app you were using (Shift+Insert through `/dev/uinput`, or XTest on X11) and puts your clipboard back afterwards.
- The emoji is marked so clipboard managers (SuperV, Klipper, CopyQ) don't record it.
- The panel stays on screen while you pick several emoji in a row; drag its edges to resize it.
- Six colour palettes (Azure, Graphite, Emerald, Amber, Rose, Violet); the glass takes the palette's tint.
- Glass look: a see-through panel (KDE Plasma also blurs what is behind it); can be turned off.
- Search across all three tabs by name and CLDR keywords; recently used first; skin tones.
- Only emoji your installed fonts can draw are shown.
- Shortcut set up automatically on GNOME, Cinnamon, MATE, Xfce and KDE Plasma 5/6 (Plasma's own emoji picker gets Meta+. back on uninstall).
- `superdot --insert`, `--search`, `--tab`, `--doctor` commands.
- Packages: .deb (Ubuntu, Mint, Debian), .rpm (Fedora, openSUSE), Arch PKGBUILD; `install.sh` for everything else.

[1.0.0]: https://github.com/saikatnjm/superdot/releases/tag/v1.0.0
