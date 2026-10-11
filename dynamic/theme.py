#!/usr/bin/env python3
"""Keep the Dynamic profile in sync with the active GNOME wallpaper."""

import argparse
import colorsys
import json
import math
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from urllib.parse import unquote, urlparse
import xml.etree.ElementTree as ET

import gi

gi.require_version('Gio', '2.0')
from gi.repository import Gio, GLib
from PIL import Image


HOME = Path.home()
TEMPLATE = Path(__file__).with_name('gnome-shell.css.in')
ACCENTS = {
    'red': 0, 'orange': 28, 'yellow': 51, 'green': 130,
    'teal': 177, 'blue': 215, 'purple': 268, 'pink': 328,
    'slate': 210,
}


def mix(a, b, amount):
    return tuple(round(x * (1 - amount) + y * amount) for x, y in zip(a, b))


def hex_color(color):
    return '#%02x%02x%02x' % color


def rgba(color, alpha):
    return f'rgba({color[0]}, {color[1]}, {color[2]}, {alpha})'


def luminance(color):
    channels = [n / 12.92 if n <= 0.04045 else ((n + 0.055) / 1.055) ** 2.4
                for n in (v / 255 for v in color)]
    return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]


def local_image(uri):
    parsed = urlparse(uri)
    if parsed.scheme != 'file':
        raise ValueError(f'Only local file wallpapers are supported: {uri}')
    path = Path(unquote(parsed.path))
    if path.suffix.lower() == '.xml':
        root = ET.parse(path).getroot()
        name = next((node.text for node in root.iter()
                     if node.tag in ('file', 'to', 'from') and node.text), None)
        if not name:
            raise ValueError(f'No image found in wallpaper slideshow: {path}')
        path = Path(name.strip())
    if not path.is_file():
        raise FileNotFoundError(path)
    return path


def image_palette(path, dark):
    with Image.open(path) as source:
        image = source.convert('RGB')
        image.thumbnail((160, 160), Image.Resampling.LANCZOS)
        quantized = image.quantize(colors=16, method=Image.Quantize.MEDIANCUT)
        table = quantized.getpalette()
        colors = [(count, tuple(table[index * 3:index * 3 + 3]))
                  for count, index in quantized.getcolors()]
    colors.sort(reverse=True)
    total = sum(count for count, _ in colors)
    dominant = tuple(round(sum(count * color[channel] for count, color in colors) / total)
                     for channel in range(3))

    def accent_score(item):
        count, color = item
        _, saturation, value = colorsys.rgb_to_hsv(*(x / 255 for x in color))
        usable_value = max(0.0, 1.0 - abs(value - 0.58) / 0.58)
        return saturation ** 1.25 * (0.45 + (count / total) ** 0.5) * (0.4 + usable_value)

    selected = max(colors, key=accent_score)[1]
    selected_hue, saturation, value = colorsys.rgb_to_hsv(*(x / 255 for x in selected))
    hue_x = hue_y = 0.0
    for count, color in colors:
        candidate_hue, candidate_sat, candidate_value = colorsys.rgb_to_hsv(
            *(x / 255 for x in color))
        weight = count * candidate_sat * candidate_value ** 1.6
        hue_x += math.cos(candidate_hue * math.tau) * weight
        hue_y += math.sin(candidate_hue * math.tau) * weight
    hue = ((math.atan2(hue_y, hue_x) % math.tau) / math.tau
           if math.hypot(hue_x, hue_y) > 1e-6 else selected_hue)
    neutral = saturation < 0.13
    saturation = min(0.72, max(0.38, saturation))
    value = min(0.85, max(0.65, value)) if dark else min(0.62, max(0.42, value))
    accent = ((136, 150, 165) if dark else (83, 103, 124)) if neutral else tuple(
        round(x * 255) for x in colorsys.hsv_to_rgb(hue, saturation, value))

    if dark:
        background = mix((10, 12, 18), dominant, 0.17)
        surface = mix(background, accent, 0.13)
        card = mix(surface, (255, 255, 255), 0.055)
        foreground = mix((247, 249, 251), accent, 0.065)
        shadow = 'rgba(0, 0, 0, 0.35)'
    else:
        background = mix((248, 249, 250), dominant, 0.12)
        surface = mix(background, accent, 0.065)
        card = mix(surface, (255, 255, 255), 0.45)
        foreground = mix((24, 28, 34), accent, 0.08)
        shadow = 'rgba(20, 24, 30, 0.16)'

    accent_fg = (20, 24, 30) if luminance(accent) > 0.37 else (255, 255, 255)
    hue_degrees = hue * 360
    accent_name = min((name for name in ACCENTS if name != 'slate'), key=lambda name:
                      min(abs(hue_degrees - ACCENTS[name]),
                          360 - abs(hue_degrees - ACCENTS[name])))
    if neutral:
        accent_name = 'slate'

    return {
        'wallpaper': str(path), 'dark': dark, 'accent_name': accent_name,
        'accent': accent, 'accent_fg': accent_fg, 'background': background,
        'surface': surface, 'card': card, 'foreground': foreground,
        'border': mix(surface, accent, 0.6),
        'shadow': shadow,
    }


def active_wallpaper(background, interface):
    dark = interface.get_string('color-scheme') == 'prefer-dark'
    key = 'picture-uri-dark' if dark else 'picture-uri'
    uri = background.get_string(key) or background.get_string('picture-uri')
    return local_image(uri), dark


def atomic_write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile('w', dir=path.parent, prefix='.asaputra-',
                                     encoding='utf-8', delete=False) as output:
        output.write(content)
        temp = Path(output.name)
    temp.chmod(0o644)
    os.replace(temp, path)


def extension_settings(uuid, schema_id):
    directory = HOME / '.local/share/gnome-shell/extensions' / uuid / 'schemas'
    source = Gio.SettingsSchemaSource.new_from_directory(
        str(directory), Gio.SettingsSchemaSource.get_default(), False)
    schema = source.lookup(schema_id, False)
    if schema is None:
        raise RuntimeError(f'GNOME extension schema is missing: {schema_id}')
    return Gio.Settings.new_full(schema, None, None)


def render_shell(palette):
    values = {
        'BASE_THEME': 'dark' if palette['dark'] else 'light',
        'BG': hex_color(palette['background']),
        'SURFACE': hex_color(palette['surface']),
        'CARD': hex_color(palette['card']),
        'FG': hex_color(palette['foreground']),
        'ACCENT': hex_color(palette['accent']),
        'ACCENT_FG': hex_color(palette['accent_fg']),
        'BORDER': hex_color(palette['border']),
        'BORDER_SOFT': rgba(palette['border'], 0.3),
        'HOVER': rgba(palette['accent'], 0.23),
        'GLOW': rgba(palette['accent'], 0.23),
        'SHADOW': palette['shadow'],
    }
    css = TEMPLATE.read_text()
    for name, value in values.items():
        css = css.replace(f'@{name}@', value)
    if '@' in css.split('/* Dynamic GNOME Shell palette.', 1)[1].split('*/', 1)[1].replace('@import', ''):
        raise RuntimeError('Unresolved GNOME Shell color token')
    return css


def render_gtk(palette):
    background = hex_color(palette['background'])
    foreground = hex_color(palette['foreground'])
    accent = hex_color(palette['accent'])
    accent_fg = hex_color(palette['accent_fg'])
    surface = hex_color(palette['surface'])
    return f'''/* Generated from the active wallpaper by ASAPUTRA Dynamic. */
@define-color accent_color {accent};
@define-color accent_bg_color {accent};
@define-color accent_fg_color {accent_fg};
@define-color window_bg_color {background};
@define-color window_fg_color {foreground};
@define-color view_bg_color {background};
@define-color view_fg_color {foreground};
@define-color popover_bg_color {surface};
@define-color popover_fg_color {foreground};
@define-color theme_bg_color {background};
@define-color theme_fg_color {foreground};
@define-color theme_selected_bg_color {accent};
@define-color theme_selected_fg_color {accent_fg};
window.background {{
  background-color: @window_bg_color;
  color: @window_fg_color;
}}
popover > contents {{
  background-color: @popover_bg_color;
  color: @popover_fg_color;
}}
selection {{
  background-color: @accent_bg_color;
  color: @accent_fg_color;
}}
'''


def render_kitty(palette):
    accent = palette['accent']
    foreground = palette['foreground']
    background = palette['background']
    card = palette['card']
    muted = mix(foreground, background, 0.48)
    lines = [
        '# ASAPUTRA Dynamic | generated from the active wallpaper',
        'font_family Noto Sans Mono', 'font_size 12.0',
        f'background {hex_color(background)}',
        f'foreground {hex_color(foreground)}',
        f'selection_background {hex_color(mix(background, accent, 0.40))}',
        f'selection_foreground {hex_color(foreground)}',
        f'cursor {hex_color(accent)}',
        f'cursor_text_color {hex_color(palette["accent_fg"])}',
        'cursor_shape beam', 'cursor_blink_interval 0',
        f'url_color {hex_color(accent)}',
    ]
    ansi = [background, (205, 105, 112), (116, 180, 145), (208, 178, 107),
            accent, (172, 139, 197), (105, 181, 192), foreground,
            muted, (229, 137, 143), (148, 206, 168), (228, 199, 133),
            mix(accent, (255, 255, 255), 0.23), (198, 165, 219),
            (143, 211, 220), (255, 255, 255)]
    lines.extend(f'color{index} {hex_color(color)}' for index, color in enumerate(ansi))
    lines.extend([
        'hide_window_decorations yes', 'remember_window_size no',
        'initial_window_width 960', 'initial_window_height 560',
        'window_padding_width 24', 'placement_strategy center',
        f'background_image {palette["wallpaper"]}',
        'background_image_layout cscaled', 'background_image_linear yes',
        f'background_tint {"0.91" if palette["dark"] else "0.94"}',
        'background_opacity 1.0', 'tab_bar_style powerline',
        'tab_bar_min_tabs 2', 'tab_powerline_style round',
        f'active_tab_background {hex_color(mix(card, accent, 0.24))}',
        f'active_tab_foreground {hex_color(foreground)}',
        f'inactive_tab_background {hex_color(card)}',
        f'inactive_tab_foreground {hex_color(muted)}',
        'confirm_os_window_close 0',
    ])
    return '\n'.join(lines) + '\n'


def render_prompt(palette):
    accent = palette['accent']
    foreground = palette['foreground']
    r, g, b = accent
    fr, fg, fb = foreground
    return f'''# ASAPUTRA Dynamic prompt. Sourced by ~/.bashrc in interactive shells.
case $- in *i*) ;; *) return ;; esac

dynamic_branch() {{
    local branch
    branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) || return 0
    printf '  [git:%s]' "$branch"
}}

PS1='\\[\\e[38;2;{r};{g};{b}m\\]╭─\\[\\e[38;2;{fr};{fg};{fb}m\\]\\u@\\h  \\W\\[\\e[0m\\]$(dynamic_branch)\\n\\[\\e[38;2;{r};{g};{b}m\\]╰─❯ \\[\\e[0m\\]'

if [[ -n ${{KITTY_WINDOW_ID:-}} && -t 1 && -z ${{DYNAMIC_FETCH_SHOWN:-}} ]] && command -v fastfetch >/dev/null 2>&1; then
    export DYNAMIC_FETCH_SHOWN=1
    fastfetch --config "$HOME/.config/fastfetch/config.jsonc"
fi
'''


def render_fastfetch(palette):
    color = '38;2;' + ';'.join(str(channel) for channel in palette['accent'])
    return json.dumps({
        '$schema': 'https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json',
        'logo': {'type': 'builtin', 'source': 'Debian_small', 'color': {'1': color, '2': color},
                 'padding': {'top': 1, 'left': 2, 'right': 3}},
        'display': {'separator': '  ', 'color': {'keys': color, 'title': color}},
        'modules': ['title', 'break', {'type': 'os', 'key': 'OS'},
                    {'type': 'kernel', 'key': 'Kernel'}, {'type': 'wm', 'key': 'Desktop'},
                    {'type': 'shell', 'key': 'Shell'}, {'type': 'terminal', 'key': 'Terminal'},
                    {'type': 'uptime', 'key': 'Uptime'}, {'type': 'memory', 'key': 'Memory'},
                    'break', {'type': 'colors', 'paddingLeft': 0, 'symbol': 'circle'}],
    }, indent=2) + '\n'


def apply_palette(palette, interface):
    theme = HOME / '.themes/Dynamic/gnome-shell/gnome-shell.css'
    atomic_write(theme, render_shell(palette))
    atomic_write(HOME / '.config/gtk-4.0/gtk.css', render_gtk(palette))
    atomic_write(HOME / '.config/gtk-3.0/gtk.css', render_gtk(palette))
    atomic_write(HOME / '.config/kitty/kitty.conf', render_kitty(palette))
    atomic_write(HOME / '.config/blue-ocean/prompt.bash', render_prompt(palette))
    atomic_write(HOME / '.config/fastfetch/config.jsonc', render_fastfetch(palette))

    interface.set_string('gtk-theme', 'Adwaita-dark' if palette['dark'] else 'Adwaita')
    interface.set_string('accent-color', palette['accent_name'])

    bar = extension_settings('openbar@neuromorph', 'org.gnome.shell.extensions.openbar')
    bar.delay()
    for key, color in {
        'iscolor': palette['surface'], 'dark-iscolor': palette['surface'],
        'fgcolor': palette['foreground'], 'dark-fgcolor': palette['foreground'],
        'bcolor': palette['border'], 'dark-bcolor': palette['border'],
        'hcolor': palette['accent'], 'dark-hcolor': palette['accent'],
    }.items():
        bar.set_strv(key, [f'{channel / 255:.4f}' for channel in color])
    bar.set_boolean('autotheme-refresh', False)
    bar.apply()

    taskbar = extension_settings('aztaskbar@aztaskbar.gitlab.com',
                                 'org.gnome.shell.extensions.aztaskbar')
    taskbar.set_string('indicator-color-focused', f'rgb{palette["accent"]}')

    borders = extension_settings('p7-borders@prasannavl.com',
                                  'org.gnome.shell.extensions.p7-borders')
    borders.set_string('rules', json.dumps({'class:kitty': {
        'enabled': True, 'width': 2, 'margins': 1, 'radius': 14,
        'activeColor': rgba(palette['accent'], 0.72),
        'inactiveColor': rgba(palette['accent'], 0.28),
    }}, separators=(',', ':')))

    subprocess.run(['dconf', 'write', '/org/gnome/shell/extensions/user-theme/name', "''"], check=True)
    subprocess.run(['dconf', 'write', '/org/gnome/shell/extensions/user-theme/name', "'Dynamic'"], check=True)
    marker = HOME / '.config/blue-ocean/dynamic-palette.json'
    atomic_write(marker, json.dumps({**palette, 'accent_hex': hex_color(palette['accent'])}, indent=2) + '\n')
    print(f'Dynamic palette updated: {palette["wallpaper"]} -> {hex_color(palette["accent"])}', flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--preview', action='store_true')
    mode.add_argument('--once', action='store_true')
    mode.add_argument('--watch', action='store_true')
    args = parser.parse_args()
    background = Gio.Settings.new('org.gnome.desktop.background')
    interface = Gio.Settings.new('org.gnome.desktop.interface')

    def update():
        path, dark = active_wallpaper(background, interface)
        palette = image_palette(path, dark)
        if args.preview:
            print(json.dumps({**palette, 'accent_hex': hex_color(palette['accent'])}, indent=2))
        else:
            apply_palette(palette, interface)
        return path

    if not args.watch:
        update()
        return

    current_monitor = None
    timeout_id = 0

    def refresh():
        nonlocal current_monitor, timeout_id
        timeout_id = 0
        try:
            path = update()
            if current_monitor is not None:
                current_monitor.cancel()
            current_monitor = Gio.File.new_for_path(str(path)).monitor_file(
                Gio.FileMonitorFlags.NONE, None)
            current_monitor.connect('changed', schedule)
        except Exception as error:
            print(f'Dynamic wallpaper update failed: {error}', file=sys.stderr, flush=True)
        return GLib.SOURCE_REMOVE

    def schedule(*_unused):
        nonlocal timeout_id
        if timeout_id:
            GLib.source_remove(timeout_id)
        timeout_id = GLib.timeout_add(500, refresh)

    background.connect('changed::picture-uri', schedule)
    background.connect('changed::picture-uri-dark', schedule)
    interface.connect('changed::color-scheme', schedule)
    refresh()
    GLib.MainLoop().run()


if __name__ == '__main__':
    main()
