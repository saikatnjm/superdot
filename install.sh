#!/usr/bin/env bash
# SuperDot installer — the Win+. emoji panel for Linux.
# Ubuntu, Mint, Debian, Pop!_OS, Zorin, elementary, Fedora, Arch, Manjaro, EndeavourOS, openSUSE…
#
#   ./install.sh                              Super+. (like Windows), asks for your password once
#   ./install.sh --hotkey "<Ctrl><Alt>e"      use your own shortcut (change it later from the ⚙ menu)
#   ./install.sh --no-sudo                    skip the password step (picking an emoji then only copies it)
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ID="io.github.superdot.SuperDot"
LIB_DIR="$HOME/.local/lib/superdot"
BIN_DIR="$HOME/.local/bin"
APPS_DIR="$HOME/.local/share/applications"
AUTOSTART_DIR="$HOME/.config/autostart"
HOTKEY="<Super>period"
NO_SUDO=0
while (($#)); do
  case "$1" in
    --hotkey) HOTKEY="$2"; shift 2 ;;
    --no-sudo) NO_SUDO=1; shift ;;
    -h|--help) sed -n '2,7p' "$0"; exit 0 ;;
    *) echo "unknown option: $1"; exit 2 ;;
  esac
done

A=$'\e[38;5;75m'; B=$'\e[1;38;5;75m'; N=$'\e[0m'; OK="${A}✓${N}"
step() { printf '\n%s%s%s\n' "$B" "$1" "$N"; }

# Install packages with whatever package manager this distro uses.
#   need build  -> C compiler, pkg-config, GTK 3 + X11 development files
#   need python -> Python GObject bindings (used by the one-time setup helper)
#   need font   -> a colour emoji font
need() {
  local pkgs=""
  if command -v apt-get >/dev/null; then
    case $1 in build) pkgs="build-essential pkg-config libgtk-3-dev" ;; python) pkgs="python3-gi gir1.2-glib-2.0" ;;
               font) pkgs="fonts-noto-color-emoji" ;; esac
    echo "  installing: $pkgs"; sudo apt-get install -y $pkgs >/dev/null
  elif command -v dnf >/dev/null; then
    case $1 in build) pkgs="gcc make pkgconf-pkg-config gtk3-devel libX11-devel" ;; python) pkgs="python3-gobject" ;;
               font) pkgs="google-noto-color-emoji-fonts" ;; esac
    echo "  installing: $pkgs"; sudo dnf install -y $pkgs >/dev/null || { [[ $1 == font ]] && sudo dnf install -y google-noto-emoji-color-fonts >/dev/null; }
  elif command -v pacman >/dev/null; then
    case $1 in build) pkgs="base-devel pkgconf gtk3 libx11" ;; python) pkgs="python-gobject" ;;
               font) pkgs="noto-fonts-emoji" ;; esac
    echo "  installing: $pkgs"; sudo pacman -S --needed --noconfirm $pkgs >/dev/null
  elif command -v zypper >/dev/null; then
    case $1 in build) pkgs="gcc make pkg-config gtk3-devel libX11-devel" ;; python) pkgs="python3-gobject" ;;
               font) pkgs="google-noto-coloremoji-fonts" ;; esac
    echo "  installing: $pkgs"; sudo zypper --non-interactive install $pkgs >/dev/null
  else
    echo "  Couldn't find apt, dnf, pacman or zypper. Please install:"
    case $1 in
      build)  echo "    a C compiler, make, pkg-config and the GTK 3 + X11 development packages" ;;
      python) echo "    the Python GObject bindings (often called python3-gobject or python3-gi)" ;;
      font)   echo "    a colour emoji font (Noto Color Emoji)" ;;
    esac
    [[ $1 == font ]] || exit 1
  fi
}

step "1/6  Getting the SuperDot binary"
BIN=""
if [[ "$(uname -m)" == "x86_64" && -x "$SRC_DIR/bin/superdot-x86_64" ]] \
   && "$SRC_DIR/bin/superdot-x86_64" --version >/dev/null 2>&1; then
  BIN="$SRC_DIR/bin/superdot-x86_64"
  echo "  $OK prebuilt binary works on this system ($(du -h "$BIN" | cut -f1))"
else
  echo "  building from source (prebuilt binary doesn't fit this system)…"
  if ! command -v cc >/dev/null || ! command -v make >/dev/null || ! command -v pkg-config >/dev/null \
     || ! pkg-config --exists gtk+-3.0 x11 2>/dev/null; then
    need build
  fi
  make -C "$SRC_DIR" -B >/dev/null
  BIN="$SRC_DIR/superdot"
  echo "  $OK built ($(du -h "$BIN" | cut -f1))"
fi
python3 -c 'from gi.repository import Gio' 2>/dev/null || need python
if [[ -z "$(fc-list ':charset=1f600' family 2>/dev/null)" ]]; then
  echo "  no colour emoji font found"
  ((NO_SUDO)) && echo "  please install Noto Color Emoji" || need font
fi

step "2/6  Installing to $LIB_DIR"
"$BIN_DIR/superdot" --quit >/dev/null 2>&1 || true
mkdir -p "$LIB_DIR" "$BIN_DIR" "$APPS_DIR" "$AUTOSTART_DIR"
install -m 755 "$BIN" "$LIB_DIR/superdot"
install -m 755 "$SRC_DIR/superdot-setup" "$LIB_DIR/superdot-setup"
install -m 755 "$SRC_DIR/uninstall.sh" "$LIB_DIR/uninstall.sh"
install -Dm 644 "$SRC_DIR/data/$ID.svg" "$HOME/.local/share/icons/hicolor/scalable/apps/$ID.svg"
ln -sf "$LIB_DIR/superdot" "$BIN_DIR/superdot"
ln -sf "$LIB_DIR/superdot-setup" "$BIN_DIR/superdot-setup"
echo "  $OK installed"

step "3/6  Start at login + app menu entry"
cat > "$AUTOSTART_DIR/superdot.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=SuperDot
Comment=Emoji for Linux (Super+.)
Exec="$LIB_DIR/superdot" --daemon
Icon=$ID
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF
sed "s|^Exec=superdot|Exec=\"$LIB_DIR/superdot\"|" "$SRC_DIR/data/$ID.desktop" > "$APPS_DIR/$ID.desktop"
echo "  $OK done"

step "4/6  Keyboard shortcut: $HOTKEY"
python3 "$LIB_DIR/superdot-setup" --setup-hotkeys "'$LIB_DIR/superdot' --toggle" --hotkey "$HOTKEY"

step "5/6  Typing the emoji for you"
RELOGIN=0
if [[ -w /dev/uinput ]]; then
  echo "  $OK already enabled"
elif ((NO_SUDO)); then
  echo "  skipped (--no-sudo): picking an emoji copies it; press Ctrl+V yourself"
else
  echo "  After you pick an emoji SuperDot types it for you (it presses Shift+Insert, then puts"
  echo "  your clipboard back). On Wayland that needs access to /dev/uinput — your password is needed once."
  sudo install -Dm644 "$SRC_DIR/data/70-superdot-uinput.rules" /etc/udev/rules.d/70-superdot-uinput.rules
  echo uinput | sudo tee /etc/modules-load.d/superdot-uinput.conf >/dev/null
  sudo modprobe uinput || true
  sudo udevadm control --reload-rules
  sudo udevadm trigger --action=change --sysname-match=uinput || true
  sudo udevadm settle || true
  sleep 1
  if [[ -w /dev/uinput ]]; then echo "  $OK enabled"
  else echo "  $OK installed — active after you log out and back in"; RELOGIN=1; fi
fi

step "6/6  Starting SuperDot"
setsid "$LIB_DIR/superdot" --daemon >/dev/null 2>&1 < /dev/null &
sleep 1
"$LIB_DIR/superdot-setup" --doctor | sed 's/^/  /'

printf '\n%sSuperDot is ready.%s Click into any text box and press your shortcut.\n' "$B" "$N"
((RELOGIN)) && echo "Log out and back in once so typing the emoji for you starts working."
echo "Uninstall any time: ~/.local/lib/superdot/uninstall.sh"
