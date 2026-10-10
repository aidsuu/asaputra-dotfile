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
    'dash-to-panel:/org/gnome/shell/extensions/dash-to-panel/'; do
    name="${entry%%:*}"
    path="${entry#*:}"
    dconf reset -f "$path"
    dconf load "$path" < "$backup/$name.dconf"
done

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
echo "Pengaturan dipulihkan dari $backup"
echo 'Keluar dan masuk lagi bila tampilan Shell belum sepenuhnya berubah.'
