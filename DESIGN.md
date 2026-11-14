# DESIGN.md: arah visual Kerjaqueue

Dokumen ini adalah sumber arah desain aplikasi. Setiap keputusan punya satu
baris alasan. Token warna dan ukuran ada di `lib/presentation/app_theme.dart`.

## Design Read

Membaca ini sebagai: aplikasi mobile lowongan harian untuk pekerja harian dan
pemilik UMKM di Surabaya, dengan bahasa visual "karcis antrean" (kertas, tinta,
nomor besar), dial ENERGY 2 / RHYTHM 2 / MOTION 1.

- ENERGY 2: cukup tegas untuk dikenali, tidak berteriak; pengguna datang untuk
  mencari kerja, bukan menonton.
- RHYTHM 2: daftar lowongan seragam supaya cepat dipindai, dipecah oleh satu
  karcis utama di atas beranda.
- MOTION 1: hanya umpan balik sentuhan bawaan; animasi tidak membantu orang
  yang membuka aplikasi sebentar di sela kerja.

## Ide brand: karcis antrean

Nama produknya "antrean kerja". Karcis antrean adalah benda yang dikenal semua
orang di pasar, puskesmas, dan bank: selembar kertas, satu nomor besar, satu
garis sobekan. Tiga hal itu menjadi identitas aplikasi.

| Motif | Dipakai di | Alasan |
| --- | --- | --- |
| Nomor besar | Skor kecocokan di kartu lowongan dan contoh karcis di landing | Skor adalah "nomor antrean" pengguna: makin tinggi, makin layak dilihat dulu. |
| Garis sobekan putus-putus | Pemisah isi dan aksi di kartu lowongan, pemisah bagian di landing | Memisahkan "informasi" dari "tindakan" seperti karcis memisahkan badan dan potongannya. |
| Lekukan sobekan | Logo dan ikon aplikasi | Membuat logo terbaca sebagai karcis walau kecil. |

## Warna

Tiga warna inti (kertas, tinta, hijau brand) dan satu aksen (kuning urgensi).

| Token | Nilai | Alasan |
| --- | --- | --- |
| `Surfaces.base` | `#F6F1E7` | Krem kertas karcis; tema terang dipilih karena aplikasi sering dibuka di luar ruangan pada siang hari. |
| `Surfaces.raised` | `#FFFFFF` | Kartu putih di atas krem terpisah tanpa perlu bayangan. |
| `TextTone.primary` | `#1D1B16` | Hitam tinta yang hangat, kontras 15,3:1 di atas kertas. |
| `TextTone.secondary` | `#57514A` | Teks pendukung, 7,0:1. |
| `TextTone.muted` | `#6B645A` | Keterangan kecil, 5,2:1, masih lolos AA. |
| `Accent.teal` | `#0B5D52` | Hijau botol: warna brand tunggal untuk tombol utama, skor tinggi, dan tautan. Cukup gelap untuk dipakai sebagai teks (6,9:1). |
| `Accent.amber` | `#8A5200` di atas `#F2B33C` 20% | Kuning karcis, hanya untuk urgensi "Hari ini" dan skor sedang, supaya tidak bersaing dengan warna brand. |
| `Accent.danger` | `#B3261E` | Hanya untuk galat, penolakan, dan aksi merusak. |
| `Accent.success` | `#176A3C` | Hanya untuk status "Diterima". |

Semua pasangan teks dan latar di atas dihitung dengan rumus kontras WCAG 2.1 dan
berada di atas 4,5:1.

## Tipografi

Roboto bawaan Flutter. Alasan: terpasang di semua ponsel Android, jadi tidak
menambah ukuran APK dan tidak perlu lisensi font tambahan. Karakter dibangun
lewat bobot, bukan jenis huruf: judul 800, angka skor 900 dengan angka tabular.
Tidak ada label huruf kapital berjarak lebar; semua label memakai huruf kalimat.

## Bentuk dan kedalaman

- Radius bertingkat: 10 (tag skor), 14 (tombol, kolom isian), 18 (kartu). Pil
  penuh hanya untuk tag dan chip filter, supaya beda dari tombol.
- Tanpa bayangan, glow, blur, dan gradien. Kedalaman cukup dari putih di atas
  krem dan garis tipis.
- Satu blok berwarna brand per layar: karcis "Antrean hari ini" di beranda,
  tombol utama di layar lain.

## Ikon

Material Icons bawaan, dipakai hanya bila menjelaskan fungsi (navigasi, kirim,
cari). Ikon petir dan kilau dibuang dari skor dan alasan kecocokan karena tidak
menjelaskan apa pun. Ikon toko di profil pemberi kerja menandai peran, bukan
status terverifikasi, karena aplikasi belum memverifikasi usaha.

## Logo

Karcis hijau dengan huruf K, garis sobekan, dan satu batang nomor di potongan
bawah. Digambar dengan kode (`BrandMark` di `ui_kit.dart` dan
`ic_launcher_foreground.xml`), jadi tidak ada aset gambar pihak ketiga.

## Isi dan bahasa

- Bahasa Indonesia sehari-hari, kalimat pendek, tanpa tanda pisah panjang.
- Tidak ada statistik, testimoni, atau klaim keamanan yang tidak bisa dibuktikan.
- Karcis di landing diberi label "Contoh lowongan" karena datanya contoh.

## Yang sengaja tidak dikerjakan

- Tema gelap: belum ada. Satu tema yang rapi lebih baik daripada dua tema yang
  belum diuji.
- Ikon aplikasi untuk Android 7 (API 24 dan 25) masih memakai PNG lama; ikon
  karcis berlaku di Android 8 ke atas.
