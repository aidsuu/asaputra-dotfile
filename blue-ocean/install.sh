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
    'blur-my-shell:/org/gnome/shell/extensions/blur-my-shell/' \
    'openbar:/org/gnome/shell/extensions/openbar/'; do
    name="${entry%%:*}"
    path="${entry#*:}"
    [[ -f "$backup/$name.dconf" ]] || dconf dump "$path" > "$backup/$name.dconf"
done
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
backup_file gtk4-css "$HOME/.config/gtk-4.0/gtk.css"
backup_file gtk4-dark-css "$HOME/.config/gtk-4.0/gtk-dark.css"
backup_file gtk4-assets "$HOME/.config/gtk-4.0/assets"
"$root/install-gtk.sh"
rm -rf -- "$HOME/.themes/Blue-Ocean"
cp -a -- "$root/theme" "$HOME/.themes/Blue-Ocean"
cp -- "$root/wallpaper/blue-ocean-v2.png" "$HOME/.local/share/backgrounds/blue-ocean.png"
if command -v kitty >/dev/null; then
    cp -- "$root/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
fi
cp -- "$root/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
cp -- "$root/shell/prompt.bash" "$HOME/.config/blue-ocean/prompt.bash"
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
gsettings set org.gnome.desktop.interface accent-color 'blue'
gsettings set org.gnome.desktop.interface gtk-theme 'Colloid-Dark-Compact-Nord'
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

blur=/org/gnome/shell/extensions/blur-my-shell
dconf write "$blur/panel/blur" 'false'
dconf write "$blur/panel/override-background" 'false'
dconf write "$blur/dash-to-dock/blur" 'false'
dconf write "$blur/dash-to-dock/override-background" 'false'
dconf write "$blur/overview/blur" 'true'

bar=/org/gnome/shell/extensions/openbar
dconf write "$bar/bartype" "'Islands'"
dconf write "$bar/position" "'Top'"
dconf write "$bar/height" '32.0'
dconf write "$bar/margin" '4.0'
dconf write "$bar/set-bottom-margin" 'false'
dconf write "$bar/set-overview" 'true'
dconf write "$bar/set-fullscreen" 'false'
dconf write "$bar/bgalpha" '0.0'
dconf write "$bar/iscolor" "['0.035', '0.125', '0.195']"
dconf write "$bar/dark-iscolor" "['0.035', '0.125', '0.195']"
dconf write "$bar/isalpha" '0.79'
dconf write "$bar/fgcolor" "['0.92', '0.98', '1.0']"
dconf write "$bar/dark-fgcolor" "['0.92', '0.98', '1.0']"
dconf write "$bar/bcolor" "['0.38', '0.75', '0.88']"
dconf write "$bar/dark-bcolor" "['0.38', '0.75', '0.88']"
dconf write "$bar/balpha" '0.55'
dconf write "$bar/bwidth" '1.0'
dconf write "$bar/bradius" '18.0'
dconf write "$bar/neon" 'false'
dconf write "$bar/shadow" 'true'
dconf write "$bar/shalpha" '0.24'
dconf write "$bar/hcolor" "['0.25', '0.67', '0.83']"
dconf write "$bar/dark-hcolor" "['0.25', '0.67', '0.83']"
dconf write "$bar/halpha" '0.27'
dconf write "$bar/hpad" '2.0'
dconf write "$bar/vpad" '2.0'
dconf write "$bar/menustyle" 'false'
dconf write "$bar/autotheme-refresh" 'false'

python3 - <<'PY'
import ast
import subprocess

key = ['org.gnome.shell', 'enabled-extensions']
enabled = ast.literal_eval(subprocess.check_output(['gsettings', 'get', *key], text=True))
enabled = [uuid for uuid in enabled if uuid != 'dash-to-dock@micxgx.gmail.com']
for uuid in ('blur-my-shell@aunetx', 'openbar@neuromorph'):
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
echo 'Keluar dan masuk lagi bila Open Bar belum langsung aktif di GNOME Wayland.'
