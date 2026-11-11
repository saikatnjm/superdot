#!/usr/bin/env bash
# Removes SuperDot and puts your desktop's keyboard shortcuts back the way they were.
#   uninstall.sh            keep your recently used emoji + settings
#   uninstall.sh --purge    delete them too
set -uo pipefail
LIB_DIR="$HOME/.local/lib/superdot"
ID="io.github.superdot.SuperDot"

if [[ -x "$LIB_DIR/superdot" ]]; then
  "$LIB_DIR/superdot" --quit >/dev/null 2>&1
  python3 "$LIB_DIR/superdot-setup" --remove-hotkeys
fi
rm -f "$HOME/.config/autostart/superdot.desktop" \
      "$HOME/.local/share/applications/$ID.desktop" \
      "$HOME/.local/bin/superdot" "$HOME/.local/bin/superdot-setup" \
      "$HOME/.local/share/icons/hicolor/scalable/apps/$ID.svg" \
      "$LIB_DIR/superdot" "$LIB_DIR/superdot-setup" "$LIB_DIR/uninstall.sh"
rmdir "$LIB_DIR" 2>/dev/null

if [[ -f /etc/udev/rules.d/70-superdot-uinput.rules || -f /etc/modules-load.d/superdot-uinput.conf ]]; then
  echo "Removing the permission to type for you (needs your password):"
  sudo rm -f /etc/udev/rules.d/70-superdot-uinput.rules /etc/modules-load.d/superdot-uinput.conf
  sudo udevadm control --reload-rules
fi

if [[ "${1:-}" == "--purge" ]]; then
  rm -f "$HOME/.local/share/superdot/recent.txt" \
        "$HOME/.config/superdot/config.ini" "$HOME/.config/superdot/hotkey-backup.json"
  rmdir "$HOME/.local/share/superdot" "$HOME/.config/superdot" 2>/dev/null
  echo "Recently used and settings deleted."
else
  echo "Kept your recently used emoji (~/.local/share/superdot) and settings (~/.config/superdot). Use --purge to delete."
fi
echo "SuperDot removed."
