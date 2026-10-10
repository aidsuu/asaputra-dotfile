# Blue Ocean · Debian GNOME dotfiles

Tema minimalis gelap untuk Debian 13 + GNOME 48. Dibuat agar tetap dekat dengan tampilan asli GNOME: Adwaita, aksen biru, wallpaper laut abstrak, panel bawah yang ringkas, dan terminal biru gelap.

## Isi

- `blue-ocean/wallpaper/blue-ocean.png` — wallpaper 1920 × 1080.
- `blue-ocean/theme/gnome-shell/gnome-shell.css` — warna panel, menu, dan notifikasi.
- `blue-ocean/kitty/kitty.conf` — palet terminal Kitty.
- `blue-ocean/generate_wallpaper.py` — sumber wallpaper yang dapat dibuat ulang dengan Pillow.
- `blue-ocean/install.sh` dan `restore.sh` — penerapan dan pemulihan pengaturan.

## Pasang

```bash
cd blue-ocean
./install.sh
```

Installer menyimpan snapshot pengaturan di `~/.local/state/blue-ocean-gnome/backups/` sebelum mengubahnya. Tidak memakai `sudo`. Sesi GNOME Wayland mungkin perlu keluar lalu masuk lagi agar semua perubahan Shell terlihat.

## Kembalikan

```bash
cd blue-ocean
./restore.sh
```

Pemulihan memakai snapshot terbaru yang dibuat saat pemasangan. Jika Anda mengubah pengaturan GNOME setelah pemasangan, perubahan baru pada bidang yang sama akan ikut ditimpa saat memulihkan snapshot.

## Perangkat lunak

GNOME Shell, `gsettings`, `dconf`, User Themes, Dash to Panel, dan Kitty. Installer akan melewati bagian ekstensi atau Kitty yang tidak ada. Pillow hanya dibutuhkan untuk membuat ulang wallpaper, bukan untuk memasang tema.
