import 'job.dart';
import 'profile.dart';

enum MatchBand { high, medium, low }

class Match {
  const Match({
    required this.job,
    required this.score,
    required this.skillScore,
    required this.distanceScore,
    required this.payScore,
    required this.scheduleScore,
    required this.reasons,
    required this.gaps,
  });

  final Job job;
  final int score;
  final int skillScore;
  final int distanceScore;
  final int payScore;
  final int scheduleScore;
  final List<String> reasons;
  final List<String> gaps;

  MatchBand get band {
    if (score >= 75) return MatchBand.high;
    if (score >= 45) return MatchBand.medium;
    return MatchBand.low;
  }

  String get headline => switch (band) {
    MatchBand.high => 'Sangat cocok',
    MatchBand.medium => 'Cukup cocok',
    MatchBand.low => 'Kurang cocok',
  };

  static Match evaluate(Job job, Profile profile) {
    final normalizedSkills = profile.skills
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toList();
    final matched = job.skills
        .where((s) => normalizedSkills.contains(s.trim().toLowerCase()))
        .toList();

    final int skillScore;
    final reasons = <String>[];
    final gaps = <String>[];
    if (job.skills.isEmpty) {
      skillScore = 20;
    } else if (matched.isNotEmpty) {
      skillScore = (35 * matched.length / job.skills.length).round();
      reasons.add('Keahlian ${matched.join(", ")} dibutuhkan');
    } else {
      skillScore = profile.skills.isEmpty ? 10 : 5;
      gaps.add('Keahlian belum cocok: ${job.skills.join(", ")}');
    }

    final double ratio = profile.maxDistanceKm <= 0
        ? (job.distanceKm <= 0 ? 1 : 0)
        : job.distanceKm / profile.maxDistanceKm;
    final int distanceScore = (25 * (1 - ratio).clamp(0.0, 1.0)).round();
    if (job.distanceKm <= profile.maxDistanceKm) {
      reasons.add('Jarak ${_km(job.distanceKm)} km, terjangkau');
    } else {
      gaps.add('Jarak ${_km(job.distanceKm)} km, di luar jangkauan');
    }

    final int payScore = profile.minPay <= 0
        ? 20
        : (20 * (job.pay / profile.minPay).clamp(0.0, 1.0)).round();
    if (job.pay >= profile.minPay) {
      reasons.add('Upah memenuhi target ${job.money.formatShort()}');
    } else {
      gaps.add('Upah ${job.money.formatShort()} di bawah target');
    }

    final int overlapStart = job.startHour > profile.startHour
        ? job.startHour
        : profile.startHour;
    final int overlapEnd = job.endHour < profile.endHour
        ? job.endHour
        : profile.endHour;
    final int jobHours = job.endHour - job.startHour;
    final int overlap = overlapEnd - overlapStart;
    final int scheduleScore = jobHours <= 0
        ? 0
        : (20 * (overlap / jobHours).clamp(0.0, 1.0)).round();
    if (overlap >= jobHours && jobHours > 0) {
      reasons.add('Jam kerja masuk jadwalmu');
    } else if (overlap <= 0) {
      gaps.add('Jam kerja ${_hour(job.startHour)}-${_hour(job.endHour)} bentrok');
    } else {
      gaps.add('Hanya $overlap jam yang masuk jadwalmu');
    }

    if (job.urgency == JobUrgency.today) {
      reasons.insert(0, 'Butuh orang hari ini');
    }

    return Match(
      job: job,
      score: skillScore + distanceScore + payScore + scheduleScore,
      skillScore: skillScore,
      distanceScore: distanceScore,
      payScore: payScore,
      scheduleScore: scheduleScore,
      reasons: reasons,
      gaps: gaps,
    );
  }

  static List<Match> rank(
    List<Job> jobs,
    Profile profile, {
    bool includeFilled = false,
  }) {
    return [
      for (final job in jobs)
        if (includeFilled || !job.filled) Match.evaluate(job, profile),
    ]..sort((a, b) {
      final urgency = _urgencyWeight(b.job).compareTo(_urgencyWeight(a.job));
      if (urgency != 0) return urgency;
      return b.score.compareTo(a.score);
    });
  }

  static int _urgencyWeight(Job job) => switch (job.urgency) {
    JobUrgency.today => 2,
    JobUrgency.thisWeek => 1,
    JobUrgency.flexible => 0,
  };

  static String _km(double value) =>
      value.toStringAsFixed(1).replaceAll('.', ',');

  static String _hour(int value) => '${value.toString().padLeft(2, '0')}:00';
}
