<h1 align="center">ASAPUTRA / GNOME</h1>

<p align="center">Three calm looks for a Debian GNOME desktop.</p>
<p align="center"><code>Debian 13</code> · <code>GNOME 48</code> · <code>Wayland</code> · <code>Kitty</code></p>

| Blue Ocean | Sakura |
| :---: | :---: |
| Deep navy, muted cyan, and moonlit water | Dark plum, dusty rose, and cherry blossoms at dusk |
| <img src="blue-ocean/wallpaper/blue-ocean-v2.png" alt="Blue Ocean wallpaper" width="440"> | <img src="sakura/wallpaper/sakura-dusk.png" alt="Sakura wallpaper" width="440"> |

Both schemes put small icons for favorite and running apps in the slim top panel. The separate dock is hidden, including in the app overview. Press `Super` to search or browse all apps. Blur stays in the overview; popup blur is disabled so rounded OSDs do not sit on a square blur layer. Each scheme coordinates the wallpaper, GNOME Shell, Colloid GTK, Kitty, Bash prompt, Fastfetch, cursor, and Kitty window outline. The Kitty outline stays subtle and follows focus.

**Dynamic** keeps your current wallpaper and derives a coordinated palette from it. It updates GNOME Shell, Open Bar, the nearest GNOME accent and installed Bibata cursor, GTK, Kitty, Fastfetch, the Bash prompt, and the Kitty outline when the wallpaper changes. If the matching Bibata cursor is unavailable, it uses Adwaita. Local SVG wallpapers and timed XML slideshows are supported; slideshow colors follow the visible frame within about 30 seconds. The small top panel and dock-free layout stay the same.

## Install and switch

```bash
git clone https://github.com/aidsuu/asaputra-dotfile.git
cd asaputra-dotfile
./blue-ocean/install.sh  # Blue Ocean
./sakura/install.sh      # Sakura
./dynamic/install.sh     # Follow the active wallpaper
```

Run any installer again to switch schemes. All profiles use one original-settings backup at `~/.local/state/blue-ocean-gnome/backups/`, so switching does not replace your pre-install snapshot. Each switch also saves the current profile temporarily and restores it automatically if installation fails. Dynamic watches local wallpaper files through a user service and needs `python3-pil`, `python3-gi`, and the GdkPixbuf SVG loader. Already-open GTK and Kitty windows may need to be reopened after a wallpaper change. The installer runs in your user account; Debian amd64 does not require `sudo`. It downloads pinned sources and Debian packages, so an internet connection is required. Sign out and back in if a newly installed GNOME extension does not appear immediately.

## Restore your original desktop

```bash
./blue-ocean/restore.sh
```

`./sakura/restore.sh` and `./dynamic/restore.sh` do the same thing. Restore stops the Dynamic service and puts back the saved desktop settings, GTK files, extensions, Kitty configuration, Fastfetch configuration, and `.bashrc`. Changes made to those same files after installation will be replaced by the backup.

## Files

```text
blue-ocean/  Blue Ocean artwork, colors, and shared installer
sakura/      Sakura artwork, colors, and installer wrapper
dynamic/     Wallpaper palette generator and user service
```

The installer verifies SHA-256 checksums for [Open Bar](https://github.com/neuromorph/openbar), [App Icons Taskbar](https://gitlab.com/AndrewZaech/aztaskbar), [Blur My Shell](https://github.com/aunetx/blur-my-shell), [P7 Borders](https://github.com/prasannavl/p7-borders-shell-extension), [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme), and [Colloid GTK](https://github.com/vinceliuice/Colloid-gtk-theme). Colloid is built from the `2026-08-08` source tag. Fastfetch and Kitty are optional; their configuration is applied when present.
