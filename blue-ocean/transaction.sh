#!/usr/bin/env bash
# Save the current desktop so an interrupted profile switch can be undone.

desktop_paths=(
    "theme:$HOME/.themes/Blue-Ocean"
    "sakura-theme:$HOME/.themes/Sakura"
    "dynamic-theme:$HOME/.themes/Dynamic"
    "colloid-theme:$HOME/.themes/Colloid-Dark-Compact-Nord"
    "colloid-pink-theme:$HOME/.themes/Colloid-Pink-Dark-Compact"
    "wallpaper:$HOME/.local/share/backgrounds/blue-ocean.png"
    "sakura-wallpaper:$HOME/.local/share/backgrounds/sakura.png"
    "kitty:$HOME/.config/kitty/kitty.conf"
    "fastfetch:$HOME/.config/fastfetch/config.jsonc"
    "bashrc:$HOME/.bashrc"
    "prompt:$HOME/.config/blue-ocean/prompt.bash"
    "palette:$HOME/.config/blue-ocean/dynamic-palette.json"
    "gtk3-css:$HOME/.config/gtk-3.0/gtk.css"
    "gtk4-css:$HOME/.config/gtk-4.0/gtk.css"
    "gtk4-dark-css:$HOME/.config/gtk-4.0/gtk-dark.css"
    "gtk4-assets:$HOME/.config/gtk-4.0/assets"
    "dynamic-runtime:$HOME/.local/lib/asaputra-dynamic"
    "dynamic-service:$HOME/.config/systemd/user/asaputra-dynamic.service"
    "user-theme-extension:$HOME/.local/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.com"
    "blur-extension:$HOME/.local/share/gnome-shell/extensions/blur-my-shell@aunetx"
    "openbar-extension:$HOME/.local/share/gnome-shell/extensions/openbar@neuromorph"
    "p7-borders-extension:$HOME/.local/share/gnome-shell/extensions/p7-borders@prasannavl.com"
    "app-icons-taskbar-extension:$HOME/.local/share/gnome-shell/extensions/aztaskbar@aztaskbar.gitlab.com"
    "papirus:$HOME/.local/share/icons/Papirus"
    "papirus-dark:$HOME/.local/share/icons/Papirus-Dark"
    "papirus-light:$HOME/.local/share/icons/Papirus-Light"
    "current:$state/current"
)

desktop_settings=(
    'interface:/org/gnome/desktop/interface/'
    'background:/org/gnome/desktop/background/'
    'screensaver:/org/gnome/desktop/screensaver/'
    'user-theme:/org/gnome/shell/extensions/user-theme/'
    'dash-to-panel:/org/gnome/shell/extensions/dash-to-panel/'
    'dash-to-dock:/org/gnome/shell/extensions/dash-to-dock/'
    'app-icons-taskbar:/org/gnome/shell/extensions/aztaskbar/'
    'blur-my-shell:/org/gnome/shell/extensions/blur-my-shell/'
    'openbar:/org/gnome/shell/extensions/openbar/'
    'p7-borders:/org/gnome/shell/extensions/p7-borders/'
)

desktop_snapshot() {
    local entry name target
    mkdir -p "$state/transactions"
    transaction="$(mktemp -d "$state/transactions/switch-XXXXXXXX")"
    trap desktop_cleanup EXIT
    mkdir -p "$transaction/files" "$transaction/settings"
    for entry in "${desktop_paths[@]}"; do
        name="${entry%%:*}"
        target="${entry#*:}"
        if [[ -e "$target" || -L "$target" ]]; then
            cp -a --reflink=auto -- "$target" "$transaction/files/$name"
        else
            touch "$transaction/files/$name.absent"
        fi
    done
    for entry in "${desktop_settings[@]}"; do
        name="${entry%%:*}"
        dconf dump "${entry#*:}" > "$transaction/settings/$name.dconf"
    done
    gsettings get org.gnome.shell enabled-extensions > "$transaction/settings/enabled-extensions"
    if command -v systemctl >/dev/null; then
        systemctl --user is-enabled --quiet asaputra-dynamic.service && touch "$transaction/service-enabled" || true
        systemctl --user is-active --quiet asaputra-dynamic.service && touch "$transaction/service-active" || true
    fi
}

desktop_rollback() {
    local entry name target
    trap - ERR INT TERM
    set +e
    echo 'Installation failed; restoring the previous desktop profile.' >&2
    if command -v systemctl >/dev/null; then
        systemctl --user disable --now asaputra-dynamic.service >/dev/null 2>&1
    fi
    for entry in "${desktop_settings[@]}"; do
        name="${entry%%:*}"
        dconf reset -f "${entry#*:}"
        dconf load "${entry#*:}" < "$transaction/settings/$name.dconf"
    done
    gsettings set org.gnome.shell enabled-extensions "$(< "$transaction/settings/enabled-extensions")"
    for entry in "${desktop_paths[@]}"; do
        name="${entry%%:*}"
        target="${entry#*:}"
        rm -rf -- "$target"
        if [[ ! -e "$transaction/files/$name.absent" ]]; then
            mkdir -p -- "$(dirname -- "$target")"
            cp -a -- "$transaction/files/$name" "$target"
        fi
    done
    if command -v systemctl >/dev/null; then
        systemctl --user daemon-reload
        if [[ -e "$transaction/service-enabled" ]]; then
            systemctl --user enable asaputra-dynamic.service >/dev/null 2>&1
        fi
        if [[ -e "$transaction/service-active" ]]; then
            systemctl --user start asaputra-dynamic.service >/dev/null 2>&1
        fi
    fi
}

desktop_cleanup() {
    [[ -z "${transaction:-}" ]] || rm -rf -- "$transaction"
}

desktop_transaction_traps() {
    trap 'desktop_rollback; exit 1' ERR
    trap 'desktop_rollback; exit 130' INT
    trap 'desktop_rollback; exit 143' TERM
    trap desktop_cleanup EXIT
}

desktop_commit() {
    trap - ERR INT TERM
    desktop_cleanup
    transaction=
    trap - EXIT
}
