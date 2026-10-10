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
