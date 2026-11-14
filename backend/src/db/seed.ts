import type { Db } from './client.ts';
import { newId, nowIso } from '../lib/ids.ts';
import { hashPassword } from '../lib/password.ts';
import { serializeSkills } from './types.ts';

type SeedJob = {
  title: string;
  company: string;
  category: string;
  description: string;
  pay: number;
  payPeriod: string;
  district: string;
  distanceKm: number;
  startHour: number;
  endHour: number;
  urgency: 'today' | 'thisWeek' | 'flexible';
  skills: string[];
  contact: string;
  hoursAgo: number;
};

const JOBS: SeedJob[] = [
  {
    title: 'Barista shift pagi',
    company: 'Kopi Jempol',
    category: 'Kuliner',
    description:
      'Bantu buka gerai, seduh kopi manual, dan layani pembeli pagi. Ada pelatihan hari pertama.',
    pay: 120000,
    payPeriod: 'per hari',
    district: 'Rungkut',
    distanceKm: 1.2,
    startHour: 7,
    endHour: 12,
    urgency: 'today',
    skills: ['Barista', 'Pelayanan'],
    contact: '6281234500011',
    hoursAgo: 1,
  },
  {
    title: 'Cuci mobil 2 unit',
    company: 'Bengkel Bersih Motor',
    category: 'Kebersihan',
    description:
      'Cuci dan lap dua mobil pelanggan hari ini. Perlengkapan disediakan pemilik.',
    pay: 75000,
    payPeriod: 'borongan',
    district: 'Rungkut',
    distanceKm: 0.8,
    startHour: 9,
    endHour: 13,
    urgency: 'today',
    skills: ['Kebersihan', 'Fisik'],
    contact: '6281234500012',
    hoursAgo: 2,
  },
  {
    title: 'Jahit seragam 30 potong',
    company: 'Konveksi Bu Sri',
    category: 'Jahit',
    description:
      'Jahit seragam sekolah dasar di rumah sendiri. Pola dan kain dari konveksi.',
    pay: 450000,
    payPeriod: 'borongan',
    district: 'Wonokromo',
    distanceKm: 3.4,
    startHour: 8,
    endHour: 16,
    urgency: 'thisWeek',
    skills: ['Jahit', 'Pola'],
    contact: '6281234500013',
    hoursAgo: 5,
  },
  {
    title: 'Kurir kirim kue lewat motor',
    company: 'Toko Roti Bu Ina',
    category: 'Pengantaran',
    description:
      'Antar 8 pesanan kue ke area Surabaya selatan. Motor dan bensin disediakan.',
    pay: 90000,
    payPeriod: 'per hari',
    district: 'Sukomanunggal',
    distanceKm: 4.6,
    startHour: 10,
    endHour: 15,
    urgency: 'today',
    skills: ['Motor', 'Navigasi'],
    contact: '6281234500014',
    hoursAgo: 1,
  },
  {
    title: 'Admin posting marketplace',
    company: 'Keripik Pusaka',
    category: 'Administrasi',
    description:
      'Unggah 20 produk ke marketplace, balas chat pembeli, rapikan foto produk.',
    pay: 150000,
    payPeriod: 'per hari',
    district: 'Tegalsari',
    distanceKm: 5.2,
    startHour: 9,
    endHour: 17,
    urgency: 'thisWeek',
    skills: ['Administrasi', 'Marketplace'],
    contact: '6281234500015',
    hoursAgo: 8,
  },
  {
    title: 'Fotografer produk makanan',
    company: 'Katering Dapur Mami',
    category: 'Desain',
    description:
      'Foto 12 menu untuk katalog WhatsApp. Lampu dan tripod disediakan.',
    pay: 300000,
    payPeriod: 'borongan',
    district: 'Rungkut',
    distanceKm: 2.1,
    startHour: 13,
    endHour: 16,
    urgency: 'today',
    skills: ['Fotografi', 'Editing'],
    contact: '6281234500016',
    hoursAgo: 3,
  },
  {
    title: 'Desain logo warung',
    company: 'Warung Semangkuk',
    category: 'Desain',
    description:
      'Bikin logo sederhana untuk gerobak mie. Boleh revisi dua kali.',
    pay: 250000,
    payPeriod: 'borongan',
    district: 'Gubeng',
    distanceKm: 6.8,
    startHour: 8,
    endHour: 20,
    urgency: 'flexible',
    skills: ['Desain Grafis', 'Logo'],
    contact: '6281234500017',
    hoursAgo: 20,
  },
  {
    title: 'Penjaga stan bazar',
    company: 'Samiler Bu Cok',
    category: 'Kuliner',
    description:
      'Jaga stan bazar akhir pekan, tawarkan produk, catat penjualan.',
    pay: 180000,
    payPeriod: 'per hari',
    district: 'Wonokromo',
    distanceKm: 3,
    startHour: 10,
    endHour: 18,
    urgency: 'thisWeek',
    skills: ['Pelayanan', 'Kasir'],
    contact: '6281234500018',
    hoursAgo: 26,
  },
  {
    title: 'Tukang rapikan gudang',
    company: 'Sembako Lancar',
    category: 'Kebersihan',
    description:
      'Kelompokkan stok, susun rak, catat barang yang hampir habis.',
    pay: 80000,
    payPeriod: 'per hari',
    district: 'Rungkut',
    distanceKm: 1.9,
    startHour: 12,
    endHour: 16,
    urgency: 'flexible',
    skills: ['Fisik', 'Administrasi'],
    contact: '6281234500019',
    hoursAgo: 30,
  },
  {
    title: 'Satpam gerbang ruko malam',
    company: 'Ruko Kenjeran 3',
    category: 'Keamanan',
    description: 'Jaga gerbang kompleks ruko dari sore sampai dini hari.',
    pay: 160000,
    payPeriod: 'per hari',
    district: 'Kenjeran',
    distanceKm: 9.4,
    startHour: 19,
    endHour: 23,
    urgency: 'today',
    skills: ['Keamanan', 'Komunikasi'],
    contact: '6281234500020',
    hoursAgo: 2,
  },
  {
    title: 'Bantu masak katering',
    company: 'Katering Dapur Mami',
    category: 'Kuliner',
    description: 'Siapkan bahan dan masak lauk nasi kotak untuk 40 pesanan.',
    pay: 100000,
    payPeriod: 'per hari',
    district: 'Rungkut',
    distanceKm: 2.4,
    startHour: 5,
    endHour: 10,
    urgency: 'today',
    skills: ['Masak', 'Kebersihan'],
    contact: '6281234500016',
    hoursAgo: 1,
  },
  {
    title: 'Kasir toko kelontong',
    company: 'Toko Berkah',
    category: 'Kuliner',
    description: 'Layani pembeli, catat nota manual, dan hitung tutup kasir.',
    pay: 140000,
    payPeriod: 'per hari',
    district: 'Tegalsari',
    distanceKm: 5.6,
    startHour: 8,
    endHour: 16,
    urgency: 'thisWeek',
    skills: ['Kasir', 'Pelayanan'],
    contact: '6281234500021',
    hoursAgo: 14,
  },
];

type DemoOptions = {
  demoPassword?: string;
};

export async function seed(db: Db, options: DemoOptions = {}): Promise<void> {
  const existing = db.prepare('SELECT COUNT(*) AS total FROM jobs').get() as {
    total: number;
  };
  if (Number(existing.total) > 0) return;

  const timestamp = nowIso();
  const ownerId = newId();
  db.prepare(
    `INSERT INTO users
      (id, email, password_hash, google_sub, full_name, display_name,
       headline, district, bio, skills, experience, role, max_distance_km,
       min_pay, start_hour, end_hour, photo_url, phone, created_at, updated_at)
     VALUES (?, ?, NULL, NULL, ?, ?, ?, ?, ?, '[]', '[]', 'employer', 5, 50000,
             8, 17, NULL, '', ?, ?)`,
  ).run(
    ownerId,
    'umkm@kerjaqueue.local',
    'Kumpulan UMKM Surabaya',
    'UMKM Surabaya',
    'Akun contoh pemilik lowongan',
    'Surabaya',
    'Kumpulan UMKM yang memasang lowongan harian di Kerjaqueue.',
    timestamp,
    timestamp,
  );

  const insert = db.prepare(
    `INSERT INTO jobs
      (id, employer_id, title, company, category, description, pay, pay_period,
       district, distance_km, start_hour, end_hour, urgency, skills, contact,
       filled, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?)`,
  );

  for (const job of JOBS) {
    const createdAt = new Date(
      Date.now() - job.hoursAgo * 3_600_000,
    ).toISOString();
    insert.run(
      newId(),
      ownerId,
      job.title,
      job.company,
      job.category,
      job.description,
      job.pay,
      job.payPeriod,
      job.district,
      job.distanceKm,
      job.startHour,
      job.endHour,
      job.urgency,
      serializeSkills(job.skills),
      job.contact,
      createdAt,
      createdAt,
    );
  }

  if (options.demoPassword !== undefined && options.demoPassword !== '') {
    const hash = await hashPassword(options.demoPassword);
    const demoUser = db.prepare(
      `INSERT INTO users
        (id, email, password_hash, google_sub, full_name, display_name,
         headline, district, bio, skills, experience, role, max_distance_km,
         min_pay, start_hour, end_hour, photo_url, phone, created_at, updated_at)
       VALUES (?, ?, ?, NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, ?, ?, ?)`,
    );
    demoUser.run(
      newId(),
      'pencari@kerjaqueue.local',
      hash,
      'Rina Pratiwi',
      'Rina',
      'Pencari kerja harian · Barista & pelayanan',
      'Rungkut',
      'Biasa buka gerai kopi pagi, cepat belajar menu baru.',
      serializeSkills(['Barista', 'Pelayanan', 'Kasir']),
      '[]',
      'worker',
      8,
      90000,
      6,
      18,
      '6281234599900',
      timestamp,
      timestamp,
    );
    demoUser.run(
      newId(),
      'pemberi@kerjaqueue.local',
      hash,
      'Budi Santoso',
      'Budi',
      'Pemilik Kopi Jempol',
      'Rungkut',
      'Punya dua gerai kopi kecil di Surabaya timur.',
      '[]',
      '[]',
      'employer',
      5,
      50000,
      8,
      17,
      '6281234599901',
      timestamp,
      timestamp,
    );
  }
}
