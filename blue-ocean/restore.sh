#!/usr/bin/env bash
set -euo pipefail

state="${XDG_STATE_HOME:-$HOME/.local/state}/blue-ocean-gnome"
[[ -f "$state/latest" ]] || { echo 'Tidak ada snapshot Blue Ocean.' >&2; exit 1; }
backup="$(< "$state/latest")"
[[ -d "$backup" ]] || { echo "Snapshot tidak ditemukan: $backup" >&2; exit 1; }

for entry in \
    'interface:/org/gnome/desktop/interface/' \
    'background:/org/gnome/desktop/background/' \
    'screensaver:/org/gnome/desktop/screensaver/' \
    'user-theme:/org/gnome/shell/extensions/user-theme/' \
    'dash-to-panel:/org/gnome/shell/extensions/dash-to-panel/' \
    'dash-to-dock:/org/gnome/shell/extensions/dash-to-dock/' \
    'blur-my-shell:/org/gnome/shell/extensions/blur-my-shell/'; do
    name="${entry%%:*}"
    path="${entry#*:}"
    if [[ -f "$backup/$name.dconf" ]]; then
        dconf reset -f "$path"
        dconf load "$path" < "$backup/$name.dconf"
    fi
done

if [[ -f "$backup/shell-enabled-extensions" ]]; then
    gsettings set org.gnome.shell enabled-extensions "$(< "$backup/shell-enabled-extensions")"
fi

if command -v gnome-extensions >/dev/null && \
   gnome-extensions info dash-to-panel@jderose9.github.com >/dev/null 2>&1; then
    if [[ -e "$backup/dash-to-panel.enabled" ]]; then
        gnome-extensions enable dash-to-panel@jderose9.github.com
    elif [[ -e "$backup/dash-to-panel.disabled" ]]; then
        gnome-extensions disable dash-to-panel@jderose9.github.com
    fi
fi

restore_file() {
    local name="$1" target="$2"
    rm -rf -- "$target"
    if [[ ! -e "$backup/$name.absent" ]]; then
        cp -a -- "$backup/$name" "$target"
    fi
}

restore_file theme "$HOME/.themes/Blue-Ocean"
restore_file wallpaper "$HOME/.local/share/backgrounds/blue-ocean.png"
restore_file kitty.conf "$HOME/.config/kitty/kitty.conf"
for entry in \
    "dock-extension:$HOME/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com" \
    "blur-extension:$HOME/.local/share/gnome-shell/extensions/blur-my-shell@aunetx" \
    "papirus:$HOME/.local/share/icons/Papirus" \
    "papirus-dark:$HOME/.local/share/icons/Papirus-Dark" \
    "papirus-light:$HOME/.local/share/icons/Papirus-Light"; do
    name="${entry%%:*}"
    target="${entry#*:}"
    if [[ -e "$backup/$name" || -e "$backup/$name.absent" ]]; then
        restore_file "$name" "$target"
    fi
done
echo "Pengaturan dipulihkan dari $backup"
echo 'Keluar dan masuk lagi bila tampilan Shell belum sepenuhnya berubah.'
