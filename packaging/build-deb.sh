#!/usr/bin/env bash
# Builds dist/superdot_<version>_amd64.deb: the double-click installer for Ubuntu, Mint, Debian, Pop!_OS…
# Usage: packaging/build-deb.sh   (uses bin/superdot-x86_64; run `make`, strip, copy it there first)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(sed -n 's/^#define VERSION *"\(.*\)"/\1/p' "$ROOT/superdot.c")"
ID=io.github.superdot.SuperDot
BIN="$ROOT/bin/superdot-x86_64"
OUT="$ROOT/dist"
PKG="$(mktemp -d)"
trap 'rm -r "$PKG"' EXIT

install -Dm755 "$BIN"                                   "$PKG/usr/bin/superdot"
install -Dm755 "$ROOT/superdot-setup"                   "$PKG/usr/lib/superdot/superdot-setup"
install -Dm644 "$ROOT/data/$ID.desktop"                 "$PKG/usr/share/applications/$ID.desktop"
install -Dm644 "$ROOT/data/$ID.svg"                     "$PKG/usr/share/icons/hicolor/scalable/apps/$ID.svg"
install -Dm644 "$ROOT/data/$ID.metainfo.xml"            "$PKG/usr/share/metainfo/$ID.metainfo.xml"
install -Dm644 "$ROOT/data/superdot-autostart.desktop"  "$PKG/etc/xdg/autostart/superdot.desktop"
# typing the emoji into Wayland apps: let the logged-in user use /dev/uinput
install -Dm644 "$ROOT/data/70-superdot-uinput.rules"    "$PKG/usr/lib/udev/rules.d/70-superdot-uinput.rules"
install -Dm644 "$ROOT/data/superdot-uinput.conf"        "$PKG/usr/lib/modules-load.d/superdot-uinput.conf"
# Debian wants every licence in one copyright file: MIT for SuperDot, Unicode for the emoji data
{ cat "$ROOT/LICENSE"; printf '\nEmoji names and keywords (built into the program) come from Unicode emoji-test.txt\nand CLDR annotations:\n\n'; cat "$ROOT/LICENSES/Unicode-3.0.txt"; } \
  | install -Dm644 /dev/stdin "$PKG/usr/share/doc/superdot/copyright"
install -d "$PKG/DEBIAN"

cat > "$PKG/DEBIAN/control" <<EOF
Package: superdot
Version: $VERSION
Section: utils
Priority: optional
Architecture: amd64
Depends: libc6 (>= 2.34), libgtk-3-0 (>= 3.22), python3, python3-gi, gir1.2-glib-2.0
Recommends: fonts-noto-color-emoji, libxtst6
Installed-Size: $(du -sk "$PKG/usr" | cut -f1)
Maintainer: SuperDot <saikatnjm@users.noreply.github.com>
Homepage: https://github.com/saikatnjm/superdot
Description: Emoji for Linux: the Win+. emoji panel
 SuperDot brings the Windows emoji panel (Win+.) to Linux. Press Super+. in
 any app, type to search, and pick an emoji, kaomoji or symbol: it is typed
 where you were writing, and your clipboard is put back afterwards. Skin
 tones, recently used, and only the emoji your fonts can draw. Works on GNOME,
 KDE Plasma, Cinnamon, MATE and Xfce, on Wayland and X11.
 .
 A single small C program; no network access.
EOF
echo /etc/xdg/autostart/superdot.desktop > "$PKG/DEBIAN/conffiles"

cat > "$PKG/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
if [ "$1" = configure ]; then
    modprobe uinput 2>/dev/null || true
    if command -v udevadm >/dev/null; then
        udevadm control --reload-rules || true
        udevadm trigger --action=change --sysname-match=uinput || true
    fi
    command -v gtk-update-icon-cache >/dev/null && gtk-update-icon-cache -q /usr/share/icons/hicolor || true
    command -v update-desktop-database >/dev/null && update-desktop-database -q /usr/share/applications || true
fi
exit 0
EOF
cat > "$PKG/DEBIAN/prerm" <<'EOF'
#!/bin/sh
# On removal, stop SuperDot and give the desktop its shortcuts back for every logged-in user.
set -e
if [ "$1" = remove ] || [ "$1" = purge ]; then
    for dir in /run/user/*; do
        uid="${dir##*/}"; bus="$dir/bus"
        [ -S "$bus" ] || continue
        user="$(id -nu "$uid" 2>/dev/null)" || continue
        runuser -u "$user" -- env DBUS_SESSION_BUS_ADDRESS="unix:path=$bus" \
            python3 /usr/lib/superdot/superdot-setup --remove-hotkeys >/dev/null 2>&1 || true
        runuser -u "$user" -- env DBUS_SESSION_BUS_ADDRESS="unix:path=$bus" \
            gdbus call --session --dest io.github.superdot.SuperDot --object-path /io/github/superdot/SuperDot \
            --method org.gtk.Actions.Activate quit "[]" "{}" >/dev/null 2>&1 || true
    done
fi
exit 0
EOF
chmod 755 "$PKG/DEBIAN/postinst" "$PKG/DEBIAN/prerm"
chmod 755 "$PKG"
find "$PKG" -type d -exec chmod 755 {} +
find "$PKG" -type f ! -path "*/DEBIAN/*" ! -path "*/usr/bin/*" ! -name superdot-setup -exec chmod 644 {} +
mkdir -p "$OUT"
dpkg-deb --root-owner-group -Zxz --build "$PKG" "$OUT/superdot_${VERSION}_amd64.deb" >/dev/null
cp "$OUT/superdot_${VERSION}_amd64.deb" "$OUT/superdot_amd64.deb"   # stable name for "latest release" links
ls -l "$OUT"
