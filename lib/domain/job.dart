import 'money.dart';

enum JobUrgency { today, thisWeek, flexible }

enum ApplicationStatus { sent, viewed, interview, accepted, rejected, withdrawn }

extension JobUrgencyX on JobUrgency {
  String get wire => switch (this) {
    JobUrgency.today => 'today',
    JobUrgency.thisWeek => 'thisWeek',
    JobUrgency.flexible => 'flexible',
  };

  String get label => switch (this) {
    JobUrgency.today => 'Hari ini',
    JobUrgency.thisWeek => 'Minggu ini',
    JobUrgency.flexible => 'Fleksibel',
  };

  static JobUrgency parse(String? raw) => switch (raw) {
    'today' => JobUrgency.today,
    'thisWeek' => JobUrgency.thisWeek,
    _ => JobUrgency.flexible,
  };
}

extension ApplicationStatusX on ApplicationStatus {
  String get wire => name;

  String get label => switch (this) {
    ApplicationStatus.sent => 'Terkirim',
    ApplicationStatus.viewed => 'Dilihat',
    ApplicationStatus.interview => 'Diwawancara',
    ApplicationStatus.accepted => 'Diterima',
    ApplicationStatus.rejected => 'Ditolak',
    ApplicationStatus.withdrawn => 'Ditarik',
  };

  static ApplicationStatus parse(String? raw) => switch (raw) {
    'viewed' => ApplicationStatus.viewed,
    'interview' => ApplicationStatus.interview,
    'accepted' => ApplicationStatus.accepted,
    'rejected' => ApplicationStatus.rejected,
    'withdrawn' => ApplicationStatus.withdrawn,
    _ => ApplicationStatus.sent,
  };
}

class EmployerSummary {
  const EmployerSummary({
    required this.id,
    required this.fullName,
    required this.displayName,
    this.photoUrl,
    this.headline = '',
  });

  final String id;
  final String fullName;
  final String displayName;
  final String? photoUrl;
  final String headline;

  factory EmployerSummary.fromJson(Map<String, dynamic> json) =>
      EmployerSummary(
        id: json['id'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        photoUrl: json['photoUrl'] as String?,
        headline: json['headline'] as String? ?? '',
      );

  static EmployerSummary? maybe(Object? raw) {
    if (raw is! Map) return null;
    return EmployerSummary.fromJson(Map<String, dynamic>.from(raw));
  }
}

class Job {
  const Job({
    required this.id,
    required this.employerId,
    required this.title,
    required this.company,
    required this.category,
    required this.description,
    required this.pay,
    required this.payPeriod,
    required this.district,
    required this.distanceKm,
    required this.startHour,
    required this.endHour,
    required this.urgency,
    required this.createdAt,
    this.skills = const [],
    this.contact = '',
    this.filled = false,
    this.employer,
    this.applicationId,
    this.applicationStatus,
    this.applicantCount = 0,
  });

  final String id;
  final String employerId;
  final String title;
  final String company;
  final String category;
  final String description;
  final int pay;
  final String payPeriod;
  final String district;
  final double distanceKm;
  final int startHour;
  final int endHour;
  final JobUrgency urgency;
  final DateTime createdAt;
  final List<String> skills;
  final String contact;
  final bool filled;
  final EmployerSummary? employer;
  final String? applicationId;
  final ApplicationStatus? applicationStatus;
  final int applicantCount;

  Money get money => Money(pay);

  bool get applied => applicationId != null;

  factory Job.fromJson(Map<String, dynamic> json) {
    final application = json['application'];
    return Job(
      id: json['id'] as String,
      employerId: json['employerId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      company: json['company'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      pay: (json['pay'] as num?)?.toInt() ?? 0,
      payPeriod: json['payPeriod'] as String? ?? 'per hari',
      district: json['district'] as String? ?? '',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      startHour: (json['startHour'] as num?)?.toInt() ?? 0,
      endHour: (json['endHour'] as num?)?.toInt() ?? 0,
      urgency: JobUrgencyX.parse(json['urgency'] as String?),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      skills:
          (json['skills'] as List?)?.cast<String>() ?? const <String>[],
      contact: json['contact'] as String? ?? '',
      filled: json['filled'] as bool? ?? false,
      employer: EmployerSummary.maybe(json['employer']),
      applicationId: application is Map ? application['id'] as String? : null,
      applicationStatus: application is Map
          ? ApplicationStatusX.parse(application['status'] as String?)
          : null,
      applicantCount: (json['applicantCount'] as num?)?.toInt() ?? 0,
    );
  }

  Job copyWith({bool? filled, ApplicationStatus? applicationStatus, String? applicationId}) => Job(
    id: id,
    employerId: employerId,
    title: title,
    company: company,
    category: category,
    description: description,
    pay: pay,
    payPeriod: payPeriod,
    district: district,
    distanceKm: distanceKm,
    startHour: startHour,
    endHour: endHour,
    urgency: urgency,
    createdAt: createdAt,
    skills: skills,
    contact: contact,
    filled: filled ?? this.filled,
    employer: employer,
    applicationId: applicationId ?? this.applicationId,
    applicationStatus: applicationStatus ?? this.applicationStatus,
    applicantCount: applicantCount,
  );
}
