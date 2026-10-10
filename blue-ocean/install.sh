#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
scheme="${1:-blue-ocean}"
case "$scheme" in
    blue-ocean)
        theme_root="$root"
        shell_theme=Blue-Ocean
        gtk_theme=Colloid-Dark-Compact-Nord
        accent=blue
        cursor=Bibata-Material-Deep-Blue
        wallpaper_source="$theme_root/wallpaper/blue-ocean-v2.png"
        wallpaper_target="$HOME/.local/share/backgrounds/blue-ocean.png"
        ;;
    sakura)
        theme_root="$root/../sakura"
        shell_theme=Sakura
        gtk_theme=Colloid-Pink-Dark-Compact
        accent=pink
        cursor=Bibata-Material-Pink-Pastel
        wallpaper_source="$theme_root/wallpaper/sakura-dusk.png"
        wallpaper_target="$HOME/.local/share/backgrounds/sakura.png"
        ;;
    *) echo "Unknown color scheme: $scheme" >&2; exit 1 ;;
esac
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
    command -v "$app" >/dev/null || { echo "Missing required command: $app" >&2; exit 1; }
done
[[ "$(gnome-shell --version)" == *' 48.'* ]] || { echo 'This setup requires GNOME Shell 48.' >&2; exit 1; }
[[ -f "$wallpaper_source" ]] || { echo "$scheme wallpaper is missing." >&2; exit 1; }
mkdir -p "$HOME/.themes" "$HOME/.local/share/backgrounds" "$HOME/.config/kitty" "$HOME/.config/fastfetch" "$HOME/.config/blue-ocean"

if "$first_install"; then
    for entry in \
        'interface:/org/gnome/desktop/interface/' \
        'background:/org/gnome/desktop/background/' \
        'screensaver:/org/gnome/desktop/screensaver/' \
        'user-theme:/org/gnome/shell/extensions/user-theme/' \
        'openbar:/org/gnome/shell/extensions/openbar/' \
        'dash-to-panel:/org/gnome/shell/extensions/dash-to-panel/'; do
        name="${entry%%:*}"
        path="${entry#*:}"
        dconf dump "$path" > "$backup/$name.dconf"
    done
fi

for entry in \
    'dash-to-dock:/org/gnome/shell/extensions/dash-to-dock/' \
    'app-icons-taskbar:/org/gnome/shell/extensions/aztaskbar/' \
    'blur-my-shell:/org/gnome/shell/extensions/blur-my-shell/' \
    'openbar:/org/gnome/shell/extensions/openbar/'; do
    name="${entry%%:*}"
    path="${entry#*:}"
    [[ -f "$backup/$name.dconf" ]] || dconf dump "$path" > "$backup/$name.dconf"
done
[[ -f "$backup/p7-borders.dconf" ]] || \
    dconf dump /org/gnome/shell/extensions/p7-borders/ > "$backup/p7-borders.dconf"
[[ -f "$backup/shell-enabled-extensions" ]] || \
    gsettings get org.gnome.shell enabled-extensions > "$backup/shell-enabled-extensions"
"$root/install-components.sh" "$backup"

backup_file() {
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

if "$first_install"; then
    backup_file theme "$HOME/.themes/Blue-Ocean"
    backup_file wallpaper "$HOME/.local/share/backgrounds/blue-ocean.png"
    backup_file kitty.conf "$HOME/.config/kitty/kitty.conf"
fi
backup_file fastfetch "$HOME/.config/fastfetch/config.jsonc"
backup_file bashrc "$HOME/.bashrc"
backup_file prompt "$HOME/.config/blue-ocean/prompt.bash"
backup_file colloid-theme "$HOME/.themes/Colloid-Dark-Compact-Nord"
backup_file sakura-theme "$HOME/.themes/Sakura"
backup_file sakura-wallpaper "$HOME/.local/share/backgrounds/sakura.png"
backup_file colloid-pink-theme "$HOME/.themes/Colloid-Pink-Dark-Compact"
backup_file gtk4-css "$HOME/.config/gtk-4.0/gtk.css"
backup_file gtk4-dark-css "$HOME/.config/gtk-4.0/gtk-dark.css"
backup_file gtk4-assets "$HOME/.config/gtk-4.0/assets"
"$root/install-gtk.sh" "$scheme"
rm -rf -- "$HOME/.themes/$shell_theme"
cp -a -- "$theme_root/theme" "$HOME/.themes/$shell_theme"
cp -- "$wallpaper_source" "$wallpaper_target"
if command -v kitty >/dev/null; then
    cp -- "$theme_root/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
fi
cp -- "$theme_root/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
cp -- "$theme_root/shell/prompt.bash" "$HOME/.config/blue-ocean/prompt.bash"
python3 - "$HOME/.bashrc" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
start = '# >>> Blue Ocean prompt >>>'
end = '# <<< Blue Ocean prompt <<<'
content = path.read_text() if path.exists() else ''
if start in content and end in content:
    first = content.index(start)
    last = content.index(end, first) + len(end)
    content = content[:first].rstrip() + content[last:].lstrip('\n')
content = content.rstrip() + '\n\n' + start + '\n'
content += '[ -f "$HOME/.config/blue-ocean/prompt.bash" ] && . "$HOME/.config/blue-ocean/prompt.bash"\n'
content += end + '\n'
path.write_text(content)
PY

gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface accent-color "$accent"
gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface cursor-theme "$cursor"
gsettings set org.gnome.desktop.interface font-name 'Cantarell 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'Noto Sans Mono 11'
gsettings set org.gnome.desktop.interface clock-show-date false
wallpaper_uri="file://$wallpaper_target"
gsettings set org.gnome.desktop.background picture-uri "$wallpaper_uri"
gsettings set org.gnome.desktop.background picture-uri-dark "$wallpaper_uri"
gsettings set org.gnome.desktop.screensaver picture-uri "$wallpaper_uri"

if gnome-extensions info user-theme@gnome-shell-extensions.gcampax.github.com >/dev/null 2>&1; then
    dconf write /org/gnome/shell/extensions/user-theme/name "''"
    dconf write /org/gnome/shell/extensions/user-theme/name "'$shell_theme'"
else
    echo 'User Themes is unavailable; skipping GNOME Shell styling.'
fi

blur=/org/gnome/shell/extensions/blur-my-shell
dconf write "$blur/panel/blur" 'false'
dconf write "$blur/panel/override-background" 'false'
dconf write "$blur/dash-to-dock/blur" 'false'
dconf write "$blur/dash-to-dock/override-background" 'false'
dconf write "$blur/overview/blur" 'true'

bar=/org/gnome/shell/extensions/openbar
if [[ "$scheme" == sakura ]]; then
    bar_iscolor="['0.11', '0.075', '0.13']"
    bar_fgcolor="['0.95', '0.89', '0.92']"
    bar_bcolor="['0.77', '0.50', '0.62']"
    bar_hcolor="['0.55', '0.28', '0.42']"
else
    bar_iscolor="['0.035', '0.125', '0.195']"
    bar_fgcolor="['0.92', '0.98', '1.0']"
    bar_bcolor="['0.38', '0.75', '0.88']"
    bar_hcolor="['0.25', '0.67', '0.83']"
fi
dconf write "$bar/bartype" "'Islands'"
dconf write "$bar/position" "'Top'"
dconf write "$bar/height" '24.0'
dconf write "$bar/margin" '1.0'
dconf write "$bar/set-bottom-margin" 'false'
dconf write "$bar/set-overview" 'true'
dconf write "$bar/set-fullscreen" 'false'
dconf write "$bar/bgalpha" '0.0'
dconf write "$bar/iscolor" "$bar_iscolor"
dconf write "$bar/dark-iscolor" "$bar_iscolor"
dconf write "$bar/isalpha" '0.79'
dconf write "$bar/fgcolor" "$bar_fgcolor"
dconf write "$bar/dark-fgcolor" "$bar_fgcolor"
dconf write "$bar/bcolor" "$bar_bcolor"
dconf write "$bar/dark-bcolor" "$bar_bcolor"
dconf write "$bar/balpha" '0.55'
dconf write "$bar/bwidth" '1.0'
dconf write "$bar/bradius" '13.0'
dconf write "$bar/neon" 'false'
dconf write "$bar/shadow" 'false'
dconf write "$bar/shalpha" '0.0'
dconf write "$bar/hcolor" "$bar_hcolor"
dconf write "$bar/dark-hcolor" "$bar_hcolor"
dconf write "$bar/halpha" '0.27'
dconf write "$bar/hpad" '1.0'
dconf write "$bar/vpad" '0.0'
dconf write "$bar/menustyle" 'false'
dconf write "$bar/autotheme-refresh" 'false'

# Put favorites and running apps in the existing slim panel, then hide the
# redundant dash in the GNOME overview.
taskbar=/org/gnome/shell/extensions/aztaskbar
dconf write "$taskbar/hide-dash" 'true'
dconf write "$taskbar/panel-on-all-monitors" 'false'
dconf write "$taskbar/panel-location" "'TOP'"
dconf write "$taskbar/main-panel-height" '(false, 26)'
dconf write "$taskbar/icon-size" '18'
dconf write "$taskbar/icon-padding-horizontal" '3'
dconf write "$taskbar/taskbar-spacing" '1'
dconf write "$taskbar/position-in-panel" "'LEFT'"
dconf write "$taskbar/position-offset" '1'
dconf write "$taskbar/favorites" 'true'
dconf write "$taskbar/show-running-apps" 'true'
dconf write "$taskbar/show-apps-button" '(false, 0)'
dconf write "$taskbar/update-notifier-enabled" 'false'
if [[ "$scheme" == sakura ]]; then
    dconf write "$taskbar/indicator-color-focused" "'rgb(202, 144, 172)'"
else
    dconf write "$taskbar/indicator-color-focused" "'rgb(119, 210, 233)'"
fi

# Keep borders exclusive to Kitty. The edge tracks the active window.
p7_schema="$HOME/.local/share/gnome-shell/extensions/p7-borders@prasannavl.com/schemas"
python3 - "$p7_schema" "$scheme" <<'PY'
import json
import sys
import gi
from gi.repository import Gio

source = Gio.SettingsSchemaSource.new_from_directory(sys.argv[1], Gio.SettingsSchemaSource.get_default(), False)
schema = source.lookup('org.gnome.shell.extensions.p7-borders', False)
if schema is None:
    raise SystemExit('P7 Borders settings schema is unavailable')
settings = Gio.Settings.new_full(schema, None, None)
settings.set_boolean('default-enabled', False)
settings.set_boolean('use-shipped-configs', False)
if sys.argv[2] == 'sakura':
    active = 'rgba(190, 133, 158, 0.78)'
    inactive = 'rgba(125, 83, 108, 0.34)'
else:
    active = 'rgba(96, 176, 205, 0.76)'
    inactive = 'rgba(64, 115, 137, 0.32)'
settings.set_string('rules', json.dumps({
    'class:kitty': {
        'enabled': True,
        'width': 2,
        'margins': 1,
        'radius': 14,
        'activeColor': active,
        'inactiveColor': inactive,
    },
}, separators=(',', ':')))
PY

python3 - <<'PY'
import ast
import subprocess

key = ['org.gnome.shell', 'enabled-extensions']
enabled = ast.literal_eval(subprocess.check_output(['gsettings', 'get', *key], text=True))
enabled = [uuid for uuid in enabled if uuid != 'dash-to-dock@micxgx.gmail.com']
for uuid in ('blur-my-shell@aunetx', 'openbar@neuromorph', 'p7-borders@prasannavl.com', 'aztaskbar@aztaskbar.gitlab.com'):
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
printf '%s\n' "$scheme" > "$state/current"
echo "$shell_theme installed. Backup: $backup"
echo 'Sign out and back in if Open Bar does not appear immediately on GNOME Wayland.'
