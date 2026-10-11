#!/usr/bin/env bash
set -euo pipefail

state="${XDG_STATE_HOME:-$HOME/.local/state}/blue-ocean-gnome"
[[ -f "$state/latest" ]] || { echo 'No Blue Ocean backup found.' >&2; exit 1; }
backup="$(< "$state/latest")"
[[ -d "$backup" ]] || { echo "Backup directory is missing: $backup" >&2; exit 1; }
if command -v systemctl >/dev/null; then
    systemctl --user disable --now asaputra-dynamic.service >/dev/null 2>&1 || true
fi

for entry in \
    'interface:/org/gnome/desktop/interface/' \
    'background:/org/gnome/desktop/background/' \
    'screensaver:/org/gnome/desktop/screensaver/' \
    'user-theme:/org/gnome/shell/extensions/user-theme/' \
    'dash-to-panel:/org/gnome/shell/extensions/dash-to-panel/' \
    'dash-to-dock:/org/gnome/shell/extensions/dash-to-dock/' \
    'app-icons-taskbar:/org/gnome/shell/extensions/aztaskbar/' \
    'blur-my-shell:/org/gnome/shell/extensions/blur-my-shell/' \
    'openbar:/org/gnome/shell/extensions/openbar/'; do
    name="${entry%%:*}"
    path="${entry#*:}"
    if [[ -f "$backup/$name.dconf" ]]; then
        dconf reset -f "$path"
        dconf load "$path" < "$backup/$name.dconf"
    fi
done
if [[ -f "$backup/p7-borders.dconf" ]]; then
    dconf reset -f /org/gnome/shell/extensions/p7-borders/
    dconf load /org/gnome/shell/extensions/p7-borders/ < "$backup/p7-borders.dconf"
fi

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
    "sakura-theme:$HOME/.themes/Sakura" \
    "sakura-wallpaper:$HOME/.local/share/backgrounds/sakura.png" \
    "colloid-pink-theme:$HOME/.themes/Colloid-Pink-Dark-Compact"; do
    name="${entry%%:*}"
    target="${entry#*:}"
    if [[ -e "$backup/$name" || -e "$backup/$name.absent" ]]; then
        restore_file "$name" "$target"
    fi
done
for entry in \
    "fastfetch:$HOME/.config/fastfetch/config.jsonc" \
    "bashrc:$HOME/.bashrc" \
    "prompt:$HOME/.config/blue-ocean/prompt.bash"; do
    name="${entry%%:*}"
    target="${entry#*:}"
    if [[ -e "$backup/$name" || -e "$backup/$name.absent" ]]; then
        restore_file "$name" "$target"
    fi
done
for entry in \
    "colloid-theme:$HOME/.themes/Colloid-Dark-Compact-Nord" \
    "dynamic-theme:$HOME/.themes/Dynamic" \
    "dynamic-runtime:$HOME/.local/lib/asaputra-dynamic" \
    "dynamic-service:$HOME/.config/systemd/user/asaputra-dynamic.service" \
    "dynamic-palette:$HOME/.config/blue-ocean/dynamic-palette.json" \
    "gtk3-css:$HOME/.config/gtk-3.0/gtk.css" \
    "gtk4-css:$HOME/.config/gtk-4.0/gtk.css" \
    "gtk4-dark-css:$HOME/.config/gtk-4.0/gtk-dark.css" \
    "gtk4-assets:$HOME/.config/gtk-4.0/assets"; do
    name="${entry%%:*}"
    target="${entry#*:}"
    if [[ -e "$backup/$name" || -e "$backup/$name.absent" ]]; then
        restore_file "$name" "$target"
    fi
done
for entry in \
    "dock-extension:$HOME/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com" \
    "blur-extension:$HOME/.local/share/gnome-shell/extensions/blur-my-shell@aunetx" \
    "openbar-extension:$HOME/.local/share/gnome-shell/extensions/openbar@neuromorph" \
    "p7-borders-extension:$HOME/.local/share/gnome-shell/extensions/p7-borders@prasannavl.com" \
    "app-icons-taskbar-extension:$HOME/.local/share/gnome-shell/extensions/aztaskbar@aztaskbar.gitlab.com" \
    "papirus:$HOME/.local/share/icons/Papirus" \
    "papirus-dark:$HOME/.local/share/icons/Papirus-Dark" \
    "papirus-light:$HOME/.local/share/icons/Papirus-Light"; do
    name="${entry%%:*}"
    target="${entry#*:}"
    if [[ -e "$backup/$name" || -e "$backup/$name.absent" ]]; then
        restore_file "$name" "$target"
    fi
done
if command -v systemctl >/dev/null; then
    systemctl --user daemon-reload
fi
echo "Settings restored from $backup"
rm -f -- "$state/current"
echo 'Sign out and back in if the Shell appearance has not fully changed.'
