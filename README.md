# Kerjaqueue

Jaringan kerja harian untuk UMKM lokal. Pencari kerja membangun profil profesional,
menemukan pekerjaan yang sesuai, mengirim lamaran, lalu berkomunikasi langsung
dengan pemberi kerja lewat pesan dalam aplikasi.

> Logicodix 2026 — HIMTI UNESA · Subtheme: Local MSME & Creative Economy
> Tim: Pejuang Mamah

## Arah produk

Kerjaqueue mengadaptasi pola jaringan profesional: profil beridentitas, feed yang
bisa dicari, lamaran berstatus, profil publik, dan percakapan pekerja–pemberi kerja.
Fokusnya tetap kebutuhan UMKM lokal yang perlu pekerja hari ini, bukan menyalin
seluruh fitur LinkedIn.

| Area | Isi |
| --- | --- |
| Identitas | Akun wajib: email + kata sandi atau Google Sign-In |
| Profil | Nama lengkap, nama panggilan, headline, kecamatan, keahlian, pengalaman |
| Beranda | Feed urgensi + skor kecocokan yang menjelaskan alasan |
| Cari | Lowongan dan profil orang; pencarian kata kunci |
| Lamaran | Status terkirim/dilihat/diwawancara/diterima/ditolak |
| Chat | Percakapan privat otomatis dibuat saat melamar |
| Asisten | Z.ai melalui backend; jawaban lokal saat API tidak tersedia |

First run menampilkan landing page dengan pilihan “Buat akun gratis”, “Masuk”,
dan Google sebelum form autentikasi. Jika OAuth Google belum dikonfigurasi, tombol
Google menampilkan alasan dan mengarahkan pengguna ke form email; itu bukan login
Google yang berhasil.

## Arsitektur

```
Flutter app ── HTTPS/JSON + Bearer JWT ──► backend (Hono + Node 24)
                                            ├── SQLite (akun, lowongan, lamaran, chat)
                                            ├── Google JWKS (verifikasi ID token)
                                            └── Z.ai API (Asisten; key hanya di server)
```

Skor kecocokan tetap dihitung di `lib/domain/match.dart`, jadi algoritme tunggal
untuk aplikasi dan bisa diuji tanpa emulator. API mengirim data lowongan mentah.

## Menjalankan

Terminal 1 — API:

```bash
cd backend
cp .env.example .env
npm install
npm start
```

Node 24+ diperlukan untuk TypeScript native dan `node:sqlite`. API default di
`http://localhost:8080`; healthcheck: `GET /health`. Pada Windows, gunakan
salinan `.env.example` sebagai `.env` lalu ubah `JWT_SECRET` dan `DEMO_PASSWORD`.

Terminal 2 — Flutter:

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

`10.0.2.2` adalah alamat host dari Android Emulator. Untuk perangkat Android fisik,
gunakan IP LAN komputer pengembang. Release publik wajib menggunakan HTTPS.

### Akun demo lokal

Saat database baru masih kosong, backend mengisi lowongan contoh dan dua akun:

| Email | Peran |
| --- | --- |
| `pencari@kerjaqueue.local` | pencari kerja |
| `pemberi@kerjaqueue.local` | pemberi kerja |

Kata sandi diambil dari `DEMO_PASSWORD`. Akun contoh hanya cocok untuk demo lokal;
matikan `SEED` dan kosongkan `DEMO_PASSWORD` untuk deploy publik.

### Google Sign-In

1. Buat OAuth 2.0 Client ID tipe **Web application** di Google Cloud.
2. Set `GOOGLE_CLIENT_ID` di backend dan `GOOGLE_SERVER_CLIENT_ID` di build Flutter
dengan Web Client ID yang sama.
3. Daftarkan package `com.logicodix.pejuangmamah` dan SHA-1 debug/release di Google
Cloud. Untuk iOS, siapkan bundle ID, URL scheme `REVERSED_CLIENT_ID`, dan uji alur
platform secara terpisah.
4. Build/run:

```bash
flutter run \
  --dart-define=API_BASE_URL=https://api.example.com \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-oauth-client-id>
```

Backend memverifikasi signature, issuer, audience, expiry, dan `email_verified`
Google ID token sebelum menukar token itu menjadi sesi Kerjaqueue. Sampai kredensial
Google didaftarkan, email + kata sandi tetap tersedia.

### Asisten Z.ai

1. Cabut/rotasi key Z.ai yang pernah ditempel di chat. Key itu dianggap bocor dan
tidak aman digunakan kembali.
2. Isi key baru sebagai environment variable/secret di server: `ZAI_API_KEY`.
3. Pastikan model `glm-4.7-flash` aktif di akun Z.ai. Model default dapat diganti
dengan `ZAI_MODEL` tanpa build ulang aplikasi.

API mengirim prompt, riwayat percakapan, ringkasan profil, dan lowongan teratas ke
Z.ai. Foto, email, dan nomor telepon tidak ikut pada payload Asisten. Batas pemakaian
harian dan rate limit diterapkan di backend; gunakan reverse proxy TLS dan observasi
biaya provider saat deploy.

## Keamanan dan privasi

- Kata sandi di-hash scrypt dengan salt unik; sesi berupa JWT HS256 berumur 30 hari.
- Jangan commit `.env`, `JWT_SECRET`, `ZAI_API_KEY`, atau kredensial OAuth.
- Google dan email memakai sesi backend yang sama; tidak ada mode tamu.
- Token sesi disimpan dengan `flutter_secure_storage` di Android Keystore/iOS Keychain;
  semua profil, lamaran, lowongan, dan pesan tetap di backend.
- Profil publik tidak mengembalikan email atau telepon. Backend hanya menyertakan
  kontak pelamar kepada pemilik lowongan.
- SQLite ditujukan untuk satu instans backend dengan volume persisten. Untuk beberapa
  instans, migrasikan implementasi `backend/src/db/` ke PostgreSQL.
- Set `APP_ORIGINS` ke origin yang benar dan tempatkan API di belakang TLS reverse
  proxy sebelum membuka ke internet.

## Pengujian

```bash
cd backend
npm test
```

```bash
flutter analyze
flutter test
```

Tes mencakup API auth/profil/lowongan/lamaran/chat, otorisasi lintas pengguna,
validasi payload, model dan skor match, pemetaan HTTP Flutter, dan alur widget login,
onboarding, feed, lamar, chat, asisten lokal, profil, serta sign-out.

## Yang belum siap untuk rilis publik

- Produksi butuh deployment server persisten, HTTPS, secret manager, backup/restore
  SQLite, monitoring, dan rencana migrasi database.
- Sediakan kebijakan privasi/retensi dan proses penghapusan akun serta data sebelum
  rilis publik; itu belum disediakan di MVP ini.
- Google OAuth, Z.ai live endpoint, iOS, accessibility audit pada perangkat nyata,
  dan pengetesan beban belum terverifikasi tanpa kredensial/deployment.
- Belum ada push notification, moderation/reporting, verifikasi usaha/identitas,
  upload avatar, atau perlindungan spam lanjutan.

## Tim

| Nama | Peran |
| --- | --- |
| _isi_ | _isi_ |
| _isi_ | _isi_ |

## Kredit

- Ikon: Material Symbols (Apache 2.0)
- API Z.ai: Z.ai
- Google Sign-In: Google
- Hono: Hono
- Font: bawaan Flutter

## Lisensi

Proyek lomba, tidak dipublikasikan ke pub.dev.
