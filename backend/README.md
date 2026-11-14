# Kerjaqueue API

Backend untuk aplikasi Kerjaqueue. Menangani akun, lowongan, lamaran,
percakapan pekerja–pemberi kerja, dan proxy Asisten AI.

Node 24 menjalankan TypeScript dan `node:sqlite` secara langsung: tidak ada
langkah build, tidak ada modul native, tidak ada layanan database terpisah.

## Menjalankan

```bash
cd backend
cp .env.example .env
npm install
npm start
```

Server default di `http://localhost:8080`. `GET /health` melaporkan apakah
integrasi Google dan Z.ai sudah aktif.

Akun demo dibuat saat database masih kosong, memakai `DEMO_PASSWORD`:

| Email | Peran |
| --- | --- |
| `pencari@kerjaqueue.local` | pencari kerja |
| `pemberi@kerjaqueue.local` | pemberi kerja |

Kata sandi dibaca dari `DEMO_PASSWORD`. Akun contoh hanya untuk development;
nonaktifkan `SEED` dan jangan set `DEMO_PASSWORD` pada deployment publik.

## Konfigurasi

| Variabel | Wajib | Guna |
| --- | --- | --- |
| `JWT_SECRET` | ya | penandatangan sesi, minimal 32 karakter |
| `DATABASE_PATH` | tidak | lokasi file SQLite, default `./data/kerjaqueue.db` |
| `APP_ORIGINS` | tidak | daftar origin CORS, pisahkan dengan koma |
| `GOOGLE_CLIENT_ID` | untuk Google | Web Client ID OAuth |
| `ZAI_API_KEY` | untuk Asisten | kunci Z.ai |
| `ZAI_MODEL` | tidak | default `glm-4.7-flash` |
| `DEMO_PASSWORD` | tidak | kata sandi untuk dua akun demo lokal |
| `SEED` | tidak | `false` mematikan seed lowongan dan akun demo |

`JWT_SECRET` dan `ZAI_API_KEY` tidak boleh masuk repo. Isi lewat environment
server atau secrets manager.

## Endpoint

Semua di bawah `/api`, JSON, dengan `Authorization: Bearer <token>` kecuali
`/auth/*`.

| Method | Path | Akses | Guna |
| --- | --- | --- | --- |
| POST | `/auth/register` | publik | daftar email + kata sandi |
| POST | `/auth/login` | publik | masuk |
| POST | `/auth/google` | publik | tukar Google ID token jadi sesi |
| GET | `/auth/me` | sesi | sesi saat ini |
| GET/PATCH | `/me` | sesi | profil diri + statistik |
| GET | `/users` | sesi | cari orang (`q`, `role`) |
| GET | `/users/:id` | sesi | profil publik |
| GET | `/jobs` | sesi | feed (`q`, `category`, `urgency`, `minPay`, `cursor`, `mine`) |
| POST | `/jobs` | sesi | pasang lowongan |
| GET/PATCH/DELETE | `/jobs/:id` | sesi | detail, tutup, hapus |
| GET | `/jobs/:id/applicants` | pemilik | daftar pelamar |
| POST | `/jobs/:id/apply` | sesi | melamar, sekaligus membuat chat |
| GET | `/applications/mine` | sesi | lamaran saya |
| GET | `/applications/inbox` | sesi | lamaran masuk |
| PATCH | `/applications/:id` | pihak terkait | ubah status |
| GET | `/chats` | sesi | daftar percakapan + unread |
| GET/POST | `/chats/:id/messages` | anggota | riwayat, kirim |
| POST | `/chats/:id/read` | anggota | tandai terbaca |
| POST | `/assistant` | sesi | Asisten AI |
| GET | `/health` | publik | healthcheck |

Aturan status lamaran: pencari kerja hanya bisa `withdrawn`; pemberi kerja
hanya bisa `viewed`, `interview`, `accepted`, `rejected`. Status `accepted`
otomatis menandai lowongan terisi.

## Keamanan

- Kata sandi di-hash scrypt dengan salt acak per pengguna.
- Sesi berupa JWT HS256, berlaku 30 hari, issuer/audience diperiksa.
- Google ID token diverifikasi terhadap JWKS Google dengan `aud` = `GOOGLE_CLIENT_ID`.
- Rate limit: auth dibatasi per IP jaringan; Asisten dibatasi per IP dan kuota harian aplikasi per pengguna.
- Body maksimal 256 KB, security header standar, CORS allowlist.
- Galat upstream Asisten dilaporkan tanpa membocorkan status atau isi dari Z.ai.
- Email dan telepon tidak pernah muncul di profil publik.

## Pengujian

```bash
npm test
```

24 tes menutup autentikasi, aturan peran dan status lamaran, feed/filter/cursor,
chat, privasi profil, dan penanganan Asisten saat kunci belum diisi.

## Deploy

Butuh proses Node 24 yang persisten dan volume untuk file SQLite.

```bash
NODE_ENV=production \
JWT_SECRET=<acak-32+ karakter> \
DATABASE_PATH=/var/lib/kerjaqueue/kerjaqueue.db \
APP_ORIGINS=https://app.example.com \
node src/index.ts
```

Pasang reverse proxy (nginx/Caddy) untuk TLS. SQLite cocok untuk satu instans;
bila perlu beberapa instans, ganti lapisan `src/db/` ke PostgreSQL.
