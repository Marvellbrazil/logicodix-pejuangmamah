import 'package:flutter_test/flutter_test.dart';
import 'package:pejuangmamah/domain/job.dart';
import 'package:pejuangmamah/domain/match.dart';
import 'package:pejuangmamah/domain/money.dart';
import 'package:pejuangmamah/domain/profile.dart';

Job job({
  String id = 'j1',
  String title = 'Barista shift pagi',
  String company = 'Kopi Jempol',
  String category = 'Kuliner',
  int pay = 120000,
  String payPeriod = 'per hari',
  String district = 'Rungkut',
  double distanceKm = 1.2,
  int startHour = 7,
  int endHour = 12,
  JobUrgency urgency = JobUrgency.today,
  List<String> skills = const ['Barista', 'Pelayanan'],
  bool filled = false,
}) => Job(
  id: id,
  employerId: 'e1',
  title: title,
  company: company,
  category: category,
  description: 'Deskripsi',
  pay: pay,
  payPeriod: payPeriod,
  district: district,
  distanceKm: distanceKm,
  startHour: startHour,
  endHour: endHour,
  urgency: urgency,
  createdAt: DateTime(2026, 11, 14, 8),
  skills: skills,
  filled: filled,
);

Profile profile({
  Set<String> skills = const {'Barista'},
  String district = 'Rungkut',
  double maxDistanceKm = 5,
  int minPay = 50000,
  int startHour = 7,
  int endHour = 15,
}) => Profile(
  id: 'u1',
  fullName: 'Rina Pratiwi',
  displayName: 'Rina',
  skills: skills.toList(),
  district: district,
  maxDistanceKm: maxDistanceKm,
  minPay: minPay,
  startHour: startHour,
  endHour: endHour,
);

void main() {
  group('Match.evaluate', () {
    test('memberi skor tinggi saat semua kriteria cocok', () {
      final match = Match.evaluate(
        job(),
        profile(skills: const {'Barista', 'Pelayanan'}, minPay: 100000),
      );
      expect(match.score, 94);
      expect(match.band, MatchBand.high);
      expect(match.skillScore, 35);
      expect(match.payScore, 20);
      expect(match.scheduleScore, 20);
      expect(match.reasons, contains('Keahlian Barista, Pelayanan dibutuhkan'));
      expect(match.reasons.first, 'Butuh orang hari ini');
    });

    test('mencatat keahlian yang tidak cocok sebagai kekurangan', () {
      final match = Match.evaluate(job(), profile(skills: const {'Jahit'}));
      expect(match.skillScore, 5);
      expect(match.gaps.any((gap) => gap.contains('Keahlian belum cocok')), true);
    });

    test('jarak di luar jangkauan mengurangi skor dan memberi catatan', () {
      final match = Match.evaluate(
        job(distanceKm: 12),
        profile(maxDistanceKm: 5),
      );
      expect(match.distanceScore, 0);
      expect(match.gaps.any((gap) => gap.contains('di luar jangkauan')), true);
    });

    test('jadwal bentrok menghasilkan skor jadwal nol', () {
      final match = Match.evaluate(
        job(startHour: 19, endHour: 23),
        profile(startHour: 6, endHour: 10),
      );
      expect(match.scheduleScore, 0);
      expect(match.gaps.any((gap) => gap.contains('bentrok')), true);
    });

    test('upah di bawah target dicatat sebagai kekurangan', () {
      final match = Match.evaluate(job(pay: 60000), profile(minPay: 150000));
      expect(match.payScore, 8);
      expect(match.gaps.any((gap) => gap.contains('di bawah target')), true);
    });

    test('lowongan tanpa syarat keahlian memberi skor netral', () {
      final match = Match.evaluate(job(skills: const []), profile());
      expect(match.skillScore, 20);
    });
  });

  group('Match.rank', () {
    test('mengurutkan urgensi hari ini lebih dulu, lalu skor', () {
      final ranked = Match.rank([
        job(id: 'a', urgency: JobUrgency.flexible),
        job(id: 'b', urgency: JobUrgency.today, pay: 50000),
        job(id: 'c', urgency: JobUrgency.thisWeek),
      ], profile(skills: const {'Barista', 'Pelayanan'}));

      expect(ranked.map((m) => m.job.id).toList(), ['b', 'c', 'a']);
    });

    test('melewati lowongan terisi secara default', () {
      final ranked = Match.rank([
        job(id: 'open'),
        job(id: 'full', filled: true),
      ], profile());
      expect(ranked.map((m) => m.job.id).toList(), ['open']);
    });

    test('includeFilled menampilkan lowongan terisi', () {
      final ranked = Match.rank([
        job(id: 'open'),
        job(id: 'full', filled: true),
      ], profile(), includeFilled: true);
      expect(ranked.length, 2);
    });
  });

  group('Money', () {
    test('format rupiah memberi titik ribuan', () {
      expect(const Money(1250000).format(), 'Rp 1.250.000');
      expect(const Money(0).format(), 'Rp 0');
    });

    test('formatShort memakai rb dan jt', () {
      expect(const Money(120000).formatShort(), 'Rp 120rb');
      expect(const Money(1500000).formatShort(), 'Rp 1,5jt');
      expect(const Money(500).formatShort(), 'Rp 500');
    });
  });

  group('Profile', () {
    test('isProfileComplete butuh nama, kecamatan, dan keahlian', () {
      expect(
        const Profile(id: 'u', fullName: 'Rina', displayName: 'R').isProfileComplete,
        false,
      );
      expect(
        Profile(
          id: 'u',
          fullName: 'Rina Pratiwi',
          displayName: 'Rina',
          district: 'Rungkut',
          skills: const ['Barista'],
        ).isProfileComplete,
        true,
      );
    });

    test('initials mengambil dua huruf awal nama', () {
      expect(profile().initials, 'RP');
      expect(
        const Profile(id: 'x', fullName: 'Budi', displayName: 'Budi').initials,
        'B',
      );
    });

    test('completeness naik seiring field terisi', () {
      final bare = const Profile(id: 'u', fullName: 'Rina', displayName: 'R');
      expect(bare.completeness, 30);
      expect(
        bare
            .copyWith(
              headline: 'Barista',
              district: 'Rungkut',
              skills: const ['Barista'],
              bio: 'Biasa buka gerai pagi',
            )
            .completeness,
            90,
      );
    });
  });

  group('Job.fromJson', () {
    test('memetakan payload API lengkap', () {
      final parsed = Job.fromJson({
        'id': 'abc',
        'employerId': 'e1',
        'title': 'Kurir kue',
        'company': 'Toko Roti',
        'category': 'Pengantaran',
        'description': 'Antar 8 pesanan',
        'pay': 90000,
        'payPeriod': 'per hari',
        'district': 'Gubeng',
        'distanceKm': 3.2,
        'startHour': 10,
        'endHour': 15,
        'urgency': 'thisWeek',
        'skills': ['Motor'],
        'filled': false,
        'createdAt': '2026-11-14T08:00:00.000Z',
        'employer': {
          'id': 'e1',
          'fullName': 'Budi Santoso',
          'displayName': 'Budi',
          'headline': 'Pemilik Kopi Jempol',
        },
        'application': {'id': 'a1', 'status': 'interview'},
        'applicantCount': 3,
      });

      expect(parsed.urgency, JobUrgency.thisWeek);
      expect(parsed.money.format(), 'Rp 90.000');
      expect(parsed.employer?.displayName, 'Budi');
      expect(parsed.applicationStatus, ApplicationStatus.interview);
      expect(parsed.applied, true);
      expect(parsed.applicantCount, 3);
    });
  });
}
