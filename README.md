# Blue Ocean · Debian GNOME dotfiles

Tema minimalis gelap untuk Debian 13 + GNOME 48. Memakai wallpaper samudra, panel atas transparan, dock aplikasi kecil yang menghilang saat jendela memerlukan ruang, ikon Papirus-Dark, dan blur ringan pada Shell. Jam dan status sistem tetap berada di panel atas. Tombol Super membuka Overview.

## Isi

- `blue-ocean/wallpaper/blue-ocean-v2.png` — wallpaper aktif; `blue-ocean.png` tetap tersedia sebagai versi awal.
- `blue-ocean/theme/gnome-shell/gnome-shell.css` — gaya Shell yang memuat stylesheet gelap GNOME 48 sebagai dasar, lalu mengubah panel, menu, quick settings, kalender, pencarian, dan notifikasi.
- `blue-ocean/kitty/kitty.conf` — palet terminal Kitty.
- `blue-ocean/install-components.sh` — memasang komponen GNOME 48 dan ikon ke folder pengguna dari paket Debian tanpa `sudo`.
- `blue-ocean/generate_wallpaper.py` — pembuat wallpaper versi awal dengan Pillow; wallpaper v2 adalah aset gambar tersendiri.
- `blue-ocean/install.sh` dan `restore.sh` — penerapan dan pemulihan pengaturan.

## Pasang

```bash
cd blue-ocean
./install.sh
```

Installer menyimpan snapshot pengaturan awal di `~/.local/state/blue-ocean-gnome/backups/` sebelum mengubahnya. Pemasangan ulang mempertahankan snapshot awal itu. Tidak memakai `sudo`. Koneksi internet dan repositori Debian diperlukan saat komponen belum terpasang. **Keluar dan masuk lagi** setelah pemasangan agar GNOME Wayland memuat ekstensi baru.

## Kembalikan

```bash
cd blue-ocean
./restore.sh
```

Pemulihan memakai snapshot terbaru yang dibuat saat pemasangan. Jika Anda mengubah pengaturan GNOME setelah pemasangan, perubahan baru pada bidang yang sama akan ikut ditimpa saat memulihkan snapshot.

## Perangkat lunak

GNOME Shell 48, `gsettings`, `dconf`, `apt-get`, `dpkg-deb`, `glib-compile-schemas`, dan Python 3. Installer memasang paket Debian Dash to Dock, Blur My Shell, dan Papirus ke folder pengguna; menonaktifkan Dash to Panel bila tersedia; dan `restore.sh` mengembalikan status serta berkas semula. User Themes dan Kitty akan dilewati bila tidak ada. Pillow hanya dibutuhkan untuk membuat ulang wallpaper awal.

Referensi: [Dash to Dock](https://github.com/micheleg/dash-to-dock), [Blur My Shell](https://github.com/aunetx/blur-my-shell), [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme), dan [tema Shell GNOME 48](https://github.com/varunbpatil/Darkwaita). Blue Ocean memakai palet, bentuk, dan wallpaper sendiri.
