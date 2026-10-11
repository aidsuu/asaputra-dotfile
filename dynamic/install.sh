#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
state="${XDG_STATE_HOME:-$HOME/.local/state}/blue-ocean-gnome"
source "$root/../blue-ocean/transaction.sh"
runtime="$HOME/.local/lib/asaputra-dynamic"
service="$HOME/.config/systemd/user/asaputra-dynamic.service"

python3 - <<'PY'
import gi
from PIL import Image
gi.require_version('Gio', '2.0')
PY

light_uri="$(gsettings get org.gnome.desktop.background picture-uri)"
dark_uri="$(gsettings get org.gnome.desktop.background picture-uri-dark)"
lock_uri="$(gsettings get org.gnome.desktop.screensaver picture-uri)"
python3 "$root/theme.py" --preview >/dev/null
desktop_snapshot
desktop_transaction_traps

# Reuse the shared backup and GNOME extension setup, then restore the user's
# wallpaper before applying its generated palette.
"$root/../blue-ocean/install.sh" sakura
gsettings set org.gnome.desktop.background picture-uri "$light_uri"
gsettings set org.gnome.desktop.background picture-uri-dark "$dark_uri"
gsettings set org.gnome.desktop.screensaver picture-uri "$lock_uri"

mkdir -p "$runtime" "$(dirname -- "$service")"
cp -- "$root/theme.py" "$root/gnome-shell.css.in" "$runtime/"
chmod 755 "$runtime/theme.py"
cp -- "$root/asaputra-dynamic.service" "$service"
"$runtime/theme.py" --once
systemctl --user daemon-reload
systemctl --user enable --now asaputra-dynamic.service
printf '%s\n' dynamic > "$state/current"
desktop_commit
echo 'Dynamic installed. Wallpaper changes now update the theme automatically.'
