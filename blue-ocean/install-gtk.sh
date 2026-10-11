#!/usr/bin/env bash
set -euo pipefail

case "${1:-blue-ocean}" in
    blue-ocean)
        gtk_variant=default
        gtk_tweaks=(nord normal)
        name=Colloid-Dark-Compact-Nord
        ;;
    sakura)
        gtk_variant=pink
        gtk_tweaks=(normal)
        name=Colloid-Pink-Dark-Compact
        ;;
    *) echo 'Unknown GTK color scheme.' >&2; exit 1 ;;
esac

# Colloid 2026-08-08, built in a temporary home. Only the GTK parts are kept.
temp="$(mktemp -d)"
trap 'rm -rf -- "$temp"' EXIT
mkdir -p "$temp/src" "$temp/home/.config/gtk-4.0" "$temp/themes" "$temp/runtime"

python3 - "$temp/src" <<'PY'
from hashlib import sha256
from io import BytesIO
from pathlib import Path
import sys
import tarfile
from urllib.request import urlopen

url = 'https://codeload.github.com/vinceliuice/Colloid-gtk-theme/tar.gz/refs/tags/2026-08-08'
expected = '58ca27f47a2ba0d7de441ea3ed8a42c8f42b693d8935c4836f6bf5ba7fc84cc1'
archive = urlopen(url, timeout=45).read()
if sha256(archive).hexdigest() != expected:
    raise SystemExit('Colloid source checksum mismatch')
destination = Path(sys.argv[1])
with tarfile.open(fileobj=BytesIO(archive), mode='r:gz') as bundle:
    bundle.extractall(destination.parent, filter='data')
source = destination.parent / 'Colloid-gtk-theme-2026-08-08'
source.rename(destination)
PY

if ! command -v sassc >/dev/null 2>&1; then
    [[ "$(dpkg --print-architecture)" == amd64 ]] || {
        echo 'sassc must be installed on architectures other than amd64.' >&2
        exit 1
    }
    for app in apt-get dpkg-deb sha256sum; do
        command -v "$app" >/dev/null || { echo "Missing required command: $app" >&2; exit 1; }
    done
    (
        cd "$temp/runtime"
        apt-get download sassc=3.6.1+20201027-2+b1 libsass1=3.6.5+20231221-3+b1
    )
    printf '%s  %s\n' \
        '28c81720dbc22c8fbaa8cf8e1ce940de10a12de0d2c867df605eb678a109b1e9' \
        "$temp/runtime/sassc_3.6.1+20201027-2+b1_amd64.deb" | sha256sum -c -
    printf '%s  %s\n' \
        '4204b4562eb5ec058da644cdad95767c2fff3eccf736322929bcf29bffafb625' \
        "$temp/runtime/libsass1_3.6.5+20231221-3+b1_amd64.deb" | sha256sum -c -
    for package in "$temp/runtime/"*.deb; do
        dpkg-deb -x "$package" "$temp/runtime"
    done
    export PATH="$temp/runtime/usr/bin:$PATH"
    export LD_LIBRARY_PATH="$temp/runtime/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi

HOME="$temp/home" XDG_DATA_HOME="$temp/home/.local/share" \
    "$temp/src/install.sh" --dest "$temp/themes" --theme "$gtk_variant" \
    --color dark --size compact --libadwaita fixed --tweaks "${gtk_tweaks[@]}"

generated="$temp/themes/$name"
[[ -s "$generated/gtk-3.0/gtk.css" && -s "$generated/gtk-4.0/gtk.css" && \
   -s "$temp/home/.config/gtk-4.0/gtk.css" ]] || {
    echo 'The generated GTK theme is incomplete.' >&2
    exit 1
}

target="$HOME/.themes/$name"
mkdir -p "$target" "$HOME/.config/gtk-4.0"
rm -rf -- "$target"
mkdir -p "$target"
cp -a -- "$generated/index.theme" "$generated/gtk-3.0" "$generated/gtk-4.0" "$target/"
rm -rf -- "$HOME/.config/gtk-4.0/assets" \
    "$HOME/.config/gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/gtk-dark.css"
cp -a -- "$temp/home/.config/gtk-4.0/assets" "$HOME/.config/gtk-4.0/"
cp -- "$temp/home/.config/gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"
