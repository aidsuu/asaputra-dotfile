<h1 align="center">BLUE OCEAN</h1>

<p align="center">A quiet GNOME desktop with deep blues, soft light, and room to breathe.</p>
<p align="center"><code>Debian 13</code> · <code>GNOME 48</code> · <code>Wayland</code> · <code>Kitty</code></p>

<p align="center">
  <img src="blue-ocean/wallpaper/blue-ocean-v2.png" alt="Blue Ocean wallpaper showing illuminated waves at night" width="920">
</p>

## The setup

| Layer | Design |
| --- | --- |
| Desktop | An original ocean wallpaper, a slim island-style top bar, and no persistent dock. Press `Super` for the app overview. |
| Applications | Colloid Nord Dark Compact for GTK 3 and GTK 4, with Papirus-Dark icons and a blue accent. |
| Terminal | A frameless Kitty window with a dimmed ocean background, clear text, and a luminous cyan outline that brightens on focus. |
| Shell | Blue Ocean menus, quick settings, search, and notifications; a softly blurred overview. |

## Install

```bash
git clone https://github.com/aidsuu/asaputra-dotfile.git
cd asaputra-dotfile
./blue-ocean/install.sh
```

The installer saves the original settings in `~/.local/state/blue-ocean-gnome/backups/` before changing them. Re-running it keeps that original backup. Everything is installed in the user account; Debian amd64 does not require `sudo`. The build downloads pinned sources and Debian packages, so an internet connection is required. If Open Bar does not appear immediately, sign out and back in.

## Restore

```bash
./blue-ocean/restore.sh
```

This restores the saved desktop settings, GTK files, extensions, Kitty configuration, Fastfetch configuration, and `.bashrc`. Changes made to those same files after installation will be replaced by the backup.

## What's inside

```text
blue-ocean/
├── wallpaper/            ocean artwork
├── theme/gnome-shell/    Shell styling
├── kitty/                terminal appearance
├── fastfetch/            compact system summary
├── shell/                Bash prompt
├── install-components.sh pinned GNOME extensions and Papirus icons
├── install-gtk.sh        Colloid GTK build
├── install.sh            apply the desktop
└── restore.sh            restore the saved setup
```

The installer verifies SHA-256 checksums for [Open Bar](https://github.com/neuromorph/openbar), [Blur My Shell](https://github.com/aunetx/blur-my-shell), [P7 Borders](https://github.com/prasannavl/p7-borders-shell-extension), [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme), and [Colloid GTK](https://github.com/vinceliuice/Colloid-gtk-theme). Colloid is built from the `2026-08-08` source tag. Fastfetch and Kitty are optional; their configuration is applied when they are present.
