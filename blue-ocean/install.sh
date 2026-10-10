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
gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'
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
echo 'Keluar dan masuk lagi bila tampilan Shell belum sepenuhnya berubah.'
