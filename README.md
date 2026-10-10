# Blue Ocean · Debian GNOME dotfiles

Tema Debian 13 + GNOME 48 bernuansa samudra. Inspirasi tata letaknya berasal dari [rion-ricing](https://github.com/SeraphimeZelel/rion-ricing): panel atas terpisah menjadi pulau kecil, terminal dengan identitas visual yang jelas, dan desktop tanpa dock permanen. Palet, wallpaper, dan konfigurasi di sini dibuat untuk Blue Ocean.

![Wallpaper Blue Ocean](blue-ocean/wallpaper/blue-ocean-v2.png)

## Isi

- `blue-ocean/wallpaper/blue-ocean-v2.png` — wallpaper aktif.
- `blue-ocean/theme/gnome-shell/gnome-shell.css` — menu, quick settings, kalender, pencarian, dan notifikasi bernuansa laut.
- `blue-ocean/kitty/kitty.conf` — terminal gelap dengan aksen cyan, dibuat tetap mudah dibaca di atas aplikasi lain.
- `blue-ocean/fastfetch/config.jsonc` dan `blue-ocean/shell/prompt.bash` — ringkasan sistem dan prompt Bash dua baris.
- `blue-ocean/install-components.sh` — memasang Open Bar 49, Blur My Shell 74, dan ikon Papirus ke folder pengguna tanpa `sudo`.
- `blue-ocean/install.sh` dan `blue-ocean/restore.sh` — menerapkan dan mengembalikan pengaturan.

Open Bar mengatur panel **Islands** yang tipis di sisi atas. Dash to Dock dinonaktifkan; tombol `Super` tetap membuka Overview untuk memilih aplikasi. Blur My Shell tetap dipakai di Overview, sehingga tidak mengganggu bentuk panel Open Bar.

## Pasang

```bash
cd blue-ocean
./install.sh
```

Installer menyimpan snapshot pengaturan awal di `~/.local/state/blue-ocean-gnome/backups/`. Pemasangan ulang mempertahankan snapshot tersebut. Koneksi internet dan repositori Debian diperlukan bila komponen belum ada. Jika Open Bar belum muncul setelah pemasangan, keluar lalu masuk lagi ke sesi GNOME Wayland.

## Kembalikan

```bash
cd blue-ocean
./restore.sh
```

Pemulihan mengembalikan pengaturan, ekstensi, file Kitty, Fastfetch, dan `.bashrc` dari snapshot. Perubahan pada bidang yang sama setelah pemasangan akan tertimpa ketika snapshot dipulihkan.

## Komponen

GNOME Shell 48, `gsettings`, `dconf`, `apt-get`, `dpkg-deb`, `glib-compile-schemas`, dan Python 3. Installer memverifikasi SHA-256 rilis [Open Bar](https://github.com/neuromorph/openbar), [Blur My Shell](https://github.com/aunetx/blur-my-shell), dan paket [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme). User Themes dan Kitty dilewati jika tidak tersedia. Fastfetch bersifat opsional; bila tersedia, ringkasan sistem muncul saat Kitty dibuka.

Rion menggunakan Fedora, Pywal, Wofi, dan wallpaper game. Konfigurasi tersebut tidak disalin karena Blue Ocean diarahkan untuk Debian GNOME dengan wallpaper samudra dan terminal Kitty.
