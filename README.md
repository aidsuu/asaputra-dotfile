# Blue Ocean · Debian GNOME dotfiles

Tema minimalis gelap untuk Debian 13 + GNOME 48. Memakai wallpaper samudra, panel atas GNOME yang tenang tanpa dock permanen, serta permukaan biru gelap yang konsisten pada menu, quick settings, kalender, pencarian, dan notifikasi. Aplikasi dapat dibuka dari Overview dengan tombol Super.

## Isi

- `blue-ocean/wallpaper/blue-ocean-v2.png` — wallpaper aktif; `blue-ocean.png` tetap tersedia sebagai versi awal.
- `blue-ocean/theme/gnome-shell/gnome-shell.css` — gaya Shell yang memuat stylesheet gelap GNOME 48 sebagai dasar, lalu mengubah panel, menu, quick settings, kalender, pencarian, dan notifikasi.
- `blue-ocean/kitty/kitty.conf` — palet terminal Kitty.
- `blue-ocean/generate_wallpaper.py` — pembuat wallpaper versi awal dengan Pillow; wallpaper v2 adalah aset gambar tersendiri.
- `blue-ocean/install.sh` dan `restore.sh` — penerapan dan pemulihan pengaturan.

## Pasang

```bash
cd blue-ocean
./install.sh
```

Installer menyimpan snapshot pengaturan awal di `~/.local/state/blue-ocean-gnome/backups/` sebelum mengubahnya. Pemasangan ulang mempertahankan snapshot awal itu. Tidak memakai `sudo`. Sesi GNOME Wayland mungkin perlu keluar lalu masuk lagi agar semua perubahan Shell terlihat.

## Kembalikan

```bash
cd blue-ocean
./restore.sh
```

Pemulihan memakai snapshot terbaru yang dibuat saat pemasangan. Jika Anda mengubah pengaturan GNOME setelah pemasangan, perubahan baru pada bidang yang sama akan ikut ditimpa saat memulihkan snapshot.

## Perangkat lunak

GNOME Shell 48, `gsettings`, `dconf`, User Themes, dan Kitty. Installer menonaktifkan Dash to Panel bila tersedia; `restore.sh` mengembalikan status awalnya. Bagian ekstensi atau Kitty yang tidak ada akan dilewati. Pillow hanya dibutuhkan untuk membuat ulang wallpaper awal, bukan untuk memasang tema.

Dasar teknis: [tema Shell GNOME 48](https://github.com/varunbpatil/Darkwaita). Blue Ocean memakai palet, bentuk, dan aset sendiri.
