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

for app in python3 glib-compile-schemas; do
    command -v "$app" >/dev/null || { echo "Perlu $app" >&2; exit 1; }
done

# These exact GNOME Extensions releases are the ones checked on GNOME 48.
python3 - "$extensions" <<'PY'
import hashlib
from io import BytesIO
import json
from pathlib import Path
import shutil
import sys
import tempfile
from urllib.request import urlopen
from zipfile import ZipFile

directory = Path(sys.argv[1])
releases = {
    'dash-to-dock@micxgx.gmail.com': (110, 76105, 'b05003e79835a35451e94931539ba1977f2a7a93b652a4fc6b7be60a77c18ae1'),
    'blur-my-shell@aunetx': (74, 75939, '9ad74044e7ece1e9a2025ddab107240fcc9b5e33ed2b2b651ea97ae7b8a29df4'),
}
for uuid, (version, tag, expected_hash) in releases.items():
    target = directory / uuid
    metadata = target / 'metadata.json'
    if metadata.exists() and json.loads(metadata.read_text()).get('version') == version:
        continue
    url = f'https://extensions.gnome.org/download-extension/{uuid}.shell-extension.zip?version_tag={tag}'
    archive = urlopen(url, timeout=30).read()
    if hashlib.sha256(archive).hexdigest() != expected_hash:
        raise SystemExit(f'Checksum ekstensi tidak cocok: {uuid}')
    with tempfile.TemporaryDirectory() as temp:
        extracted = Path(temp) / 'extension'
        extracted.mkdir()
        with ZipFile(BytesIO(archive)) as bundle:
            bundle.extractall(extracted)
        info = json.loads((extracted / 'metadata.json').read_text())
        if info.get('uuid') != uuid or info.get('version') != version or '48' not in info.get('shell-version', []):
            raise SystemExit(f'Ekstensi tidak cocok dengan GNOME 48: {uuid}')
        if target.exists():
            shutil.rmtree(target)
        shutil.copytree(extracted, target)
PY

for uuid in dash-to-dock@micxgx.gmail.com blur-my-shell@aunetx; do
    glib-compile-schemas "$extensions/$uuid/schemas"
done

need_icons=false
for name in Papirus Papirus-Dark Papirus-Light; do
    [[ -d "$icons/$name" ]] || need_icons=true
done
if "$need_icons"; then
    for app in apt-get dpkg-deb sha256sum; do
        command -v "$app" >/dev/null || { echo "Perlu $app" >&2; exit 1; }
    done
    temp="$(mktemp -d)"
    trap 'rm -rf -- "$temp"' EXIT
    (cd "$temp" && apt-get download papirus-icon-theme=20250501-1)
    package="$temp/papirus-icon-theme_20250501-1_all.deb"
    printf '%s  %s\n' 'a66fa824a217bcd7326d5adb8b910da99b621757603274001f1db01dd0d97a0b' "$package" | sha256sum -c -
    mkdir -p "$temp/extracted"
    dpkg-deb -x "$package" "$temp/extracted"
    for name in Papirus Papirus-Dark Papirus-Light; do
        [[ -d "$icons/$name" ]] || cp -a "$temp/extracted/usr/share/icons/$name" "$icons/"
    done
fi
