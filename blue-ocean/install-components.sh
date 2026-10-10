#!/usr/bin/env bash
set -euo pipefail

backup="${1:?Lokasi snapshot diperlukan}"
extensions="$HOME/.local/share/gnome-shell/extensions"
icons="$HOME/.local/share/icons"
mkdir -p "$extensions" "$icons"

record_path() {
    local name="$1" target="$2"
    if [[ -e "$backup/$name" || -e "$backup/$name.absent" ]]; then
        return
    fi
    if [[ -e "$target" || -L "$target" ]]; then
        cp -a -- "$target" "$backup/$name"
    else
        touch "$backup/$name.absent"
    fi
}

record_path dock-extension "$extensions/dash-to-dock@micxgx.gmail.com"
record_path blur-extension "$extensions/blur-my-shell@aunetx"
record_path papirus "$icons/Papirus"
record_path papirus-dark "$icons/Papirus-Dark"
record_path papirus-light "$icons/Papirus-Light"

need_download=false
for path in \
    "$extensions/dash-to-dock@micxgx.gmail.com" \
    "$extensions/blur-my-shell@aunetx" \
    "$icons/Papirus" "$icons/Papirus-Dark" "$icons/Papirus-Light"; do
    [[ -d "$path" ]] || need_download=true
done
[[ -f "$extensions/dash-to-dock@micxgx.gmail.com/schemas/org.gnome.shell.extensions.dash-to-dock.gschema.xml" ]] || need_download=true

if "$need_download"; then
    for app in apt-get dpkg-deb glib-compile-schemas; do
        command -v "$app" >/dev/null || { echo "Perlu $app" >&2; exit 1; }
    done
    temp="$(mktemp -d)"
    trap 'rm -rf -- "$temp"' EXIT
    (
        cd "$temp"
        apt-get download gnome-shell-extension-dashtodock \
            gnome-shell-extension-blur-my-shell papirus-icon-theme
    )
    mkdir -p "$temp/extracted"
    for package in "$temp"/*.deb; do
        dpkg-deb -x "$package" "$temp/extracted"
    done
    source_extensions="$temp/extracted/usr/share/gnome-shell/extensions"
    source_icons="$temp/extracted/usr/share/icons"
    [[ -d "$extensions/dash-to-dock@micxgx.gmail.com" ]] || \
        cp -a "$source_extensions/dash-to-dock@micxgx.gmail.com" "$extensions/"
    [[ -d "$extensions/blur-my-shell@aunetx" ]] || \
        cp -a "$source_extensions/blur-my-shell@aunetx" "$extensions/"
    for name in Papirus Papirus-Dark Papirus-Light; do
        [[ -d "$icons/$name" ]] || cp -a "$source_icons/$name" "$icons/"
    done
    mkdir -p "$extensions/dash-to-dock@micxgx.gmail.com/schemas"
    cp "$temp/extracted/usr/share/glib-2.0/schemas/org.gnome.shell.extensions.dash-to-dock.gschema.xml" \
        "$extensions/dash-to-dock@micxgx.gmail.com/schemas/"
fi

glib-compile-schemas "$extensions/dash-to-dock@micxgx.gmail.com/schemas"
