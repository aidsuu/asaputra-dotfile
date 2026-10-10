#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
state="${XDG_STATE_HOME:-$HOME/.local/state}/blue-ocean-gnome"
mkdir -p "$state/backups"
if [[ -f "$state/latest" ]] && [[ -d "$(< "$state/latest")" ]]; then
    backup="$(< "$state/latest")"
    first_install=false
else
    backup="$(mktemp -d "$state/backups/$(date +%Y%m%d-%H%M%S)-XXXXXX")"
    first_install=true
fi

for app in gsettings dconf; do
    command -v "$app" >/dev/null || { echo "Perlu $app" >&2; exit 1; }
done
[[ "$(gnome-shell --version)" == *' 48.'* ]] || { echo 'Blue Ocean ini memerlukan GNOME Shell 48.' >&2; exit 1; }
[[ -f "$root/wallpaper/blue-ocean-v2.png" ]] || { echo "Wallpaper Blue Ocean v2 tidak ditemukan." >&2; exit 1; }
mkdir -p "$HOME/.themes" "$HOME/.local/share/backgrounds" "$HOME/.config/kitty"

if "$first_install"; then
    for entry in \
        'interface:/org/gnome/desktop/interface/' \
        'background:/org/gnome/desktop/background/' \
        'screensaver:/org/gnome/desktop/screensaver/' \
        'user-theme:/org/gnome/shell/extensions/user-theme/' \
        'dash-to-panel:/org/gnome/shell/extensions/dash-to-panel/'; do
        name="${entry%%:*}"
        path="${entry#*:}"
        dconf dump "$path" > "$backup/$name.dconf"
    done
fi

for entry in \
    'dash-to-dock:/org/gnome/shell/extensions/dash-to-dock/' \
    'blur-my-shell:/org/gnome/shell/extensions/blur-my-shell/'; do
    name="${entry%%:*}"
    path="${entry#*:}"
    [[ -f "$backup/$name.dconf" ]] || dconf dump "$path" > "$backup/$name.dconf"
done
[[ -f "$backup/shell-enabled-extensions" ]] || \
    gsettings get org.gnome.shell enabled-extensions > "$backup/shell-enabled-extensions"
"$root/install-components.sh" "$backup"

backup_file() {
    local name="$1" target="$2"
    if [[ -e "$target" || -L "$target" ]]; then
        cp -a -- "$target" "$backup/$name"
    else
        touch "$backup/$name.absent"
    fi
}

if "$first_install"; then
    backup_file theme "$HOME/.themes/Blue-Ocean"
    backup_file wallpaper "$HOME/.local/share/backgrounds/blue-ocean.png"
    backup_file kitty.conf "$HOME/.config/kitty/kitty.conf"
fi
rm -rf -- "$HOME/.themes/Blue-Ocean"
cp -a -- "$root/theme" "$HOME/.themes/Blue-Ocean"
cp -- "$root/wallpaper/blue-ocean-v2.png" "$HOME/.local/share/backgrounds/blue-ocean.png"
if command -v kitty >/dev/null; then
    cp -- "$root/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
fi

gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface accent-color 'blue'
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Material-Deep-Blue'
gsettings set org.gnome.desktop.interface font-name 'Cantarell 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'Noto Sans Mono 11'
gsettings set org.gnome.desktop.interface clock-show-date false
wallpaper_uri="file://$HOME/.local/share/backgrounds/blue-ocean.png"
gsettings set org.gnome.desktop.background picture-uri-dark "file://$root/wallpaper/blue-ocean-v2.png"
gsettings set org.gnome.desktop.background picture-uri "$wallpaper_uri"
gsettings set org.gnome.desktop.background picture-uri-dark "$wallpaper_uri"
gsettings set org.gnome.desktop.screensaver picture-uri "$wallpaper_uri"

if gnome-extensions info user-theme@gnome-shell-extensions.gcampax.github.com >/dev/null 2>&1; then
    dconf write /org/gnome/shell/extensions/user-theme/name "''"
    dconf write /org/gnome/shell/extensions/user-theme/name "'Blue-Ocean'"
else
    echo 'User Themes tidak ada; gaya GNOME Shell dilewati.'
fi

dock=/org/gnome/shell/extensions/dash-to-dock
dconf write "$dock/dock-position" "'BOTTOM'"
dconf write "$dock/dock-fixed" 'false'
dconf write "$dock/intellihide" 'true'
dconf write "$dock/autohide" 'true'
dconf write "$dock/require-pressure-to-show" 'false'
dconf write "$dock/show-delay" '0.12'
dconf write "$dock/hide-delay" '0.18'
dconf write "$dock/dash-max-icon-size" '36'
dconf write "$dock/custom-theme-shrink" 'true'
dconf write "$dock/show-favorites" 'true'
dconf write "$dock/show-running" 'true'
dconf write "$dock/show-show-apps-button" 'true'
dconf write "$dock/show-mounts" 'false'
dconf write "$dock/show-trash" 'false'
dconf write "$dock/transparency-mode" "'FIXED'"
dconf write "$dock/custom-background-color" 'true'
dconf write "$dock/background-color" "'#0b283b'"
dconf write "$dock/background-opacity" '0.62'
dconf write "$dock/running-indicator-style" "'DOTS'"

blur=/org/gnome/shell/extensions/blur-my-shell
dconf write "$blur/panel/blur" 'true'
dconf write "$blur/panel/override-background" 'false'
dconf write "$blur/dash-to-dock/blur" 'true'
dconf write "$blur/dash-to-dock/override-background" 'false'
dconf write "$blur/dash-to-dock/corner-radius" '15'
dconf write "$blur/overview/blur" 'true'

python3 - <<'PY'
import ast
import subprocess

key = ['org.gnome.shell', 'enabled-extensions']
enabled = ast.literal_eval(subprocess.check_output(['gsettings', 'get', *key], text=True))
for uuid in ('dash-to-dock@micxgx.gmail.com', 'blur-my-shell@aunetx'):
    if uuid not in enabled:
        enabled.append(uuid)
subprocess.run(['gsettings', 'set', *key, repr(enabled)], check=True)
PY

if command -v gnome-extensions >/dev/null && \
   gnome-extensions info dash-to-panel@jderose9.github.com >/dev/null 2>&1; then
    if [[ ! -e "$backup/dash-to-panel.enabled" && ! -e "$backup/dash-to-panel.disabled" ]]; then
        if gnome-extensions list --enabled | grep -Fxq 'dash-to-panel@jderose9.github.com'; then
            touch "$backup/dash-to-panel.enabled"
        else
            touch "$backup/dash-to-panel.disabled"
        fi
    fi
    dconf reset -f /org/gnome/shell/extensions/dash-to-panel/
    dconf load /org/gnome/shell/extensions/dash-to-panel/ < "$backup/dash-to-panel.dconf"
    gnome-extensions disable dash-to-panel@jderose9.github.com
fi

if "$first_install"; then
    printf '%s\n' "$backup" > "$state/latest"
fi
echo "Blue Ocean terpasang. Cadangan: $backup"
echo 'Keluar dan masuk lagi agar GNOME Wayland memuat ekstensi baru.'
