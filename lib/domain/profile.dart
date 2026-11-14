import 'job.dart';

class Experience {
  const Experience({
    this.title = '',
    this.company = '',
    this.period = '',
    this.detail = '',
  });

  final String title;
  final String company;
  final String period;
  final String detail;

  bool get isEmpty =>
      title.isEmpty && company.isEmpty && period.isEmpty && detail.isEmpty;

  Experience copyWith({
    String? title,
    String? company,
    String? period,
    String? detail,
  }) => Experience(
    title: title ?? this.title,
    company: company ?? this.company,
    period: period ?? this.period,
    detail: detail ?? this.detail,
  );

  Map<String, Object?> toJson() => {
    'title': title,
    'company': company,
    'period': period,
    'detail': detail,
  };

  factory Experience.fromJson(Map<String, dynamic> json) => Experience(
    title: json['title'] as String? ?? '',
    company: json['company'] as String? ?? '',
    period: json['period'] as String? ?? '',
    detail: json['detail'] as String? ?? '',
  );
}

enum UserRole { worker, employer }

extension UserRoleX on UserRole {
  String get wire => name;

  String get label => switch (this) {
    UserRole.worker => 'Pencari kerja',
    UserRole.employer => 'Pemberi kerja',
  };

  static UserRole parse(String? raw) =>
      raw == 'employer' ? UserRole.employer : UserRole.worker;
}

class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    required this.displayName,
    this.headline = '',
    this.district = '',
    this.bio = '',
    this.skills = const [],
    this.experience = const [],
    this.role = UserRole.worker,
    this.photoUrl,
    this.createdAt,
    this.email = '',
    this.phone = '',
    this.maxDistanceKm = 5,
    this.minPay = 50000,
    this.startHour = 8,
    this.endHour = 17,
    this.hasPassword = false,
    this.hasGoogle = false,
  });

  final String id;
  final String fullName;
  final String displayName;
  final String headline;
  final String district;
  final String bio;
  final List<String> skills;
  final List<Experience> experience;
  final UserRole role;
  final String? photoUrl;
  final DateTime? createdAt;
  final String email;
  final String phone;
  final double maxDistanceKm;
  final int minPay;
  final int startHour;
  final int endHour;
  final bool hasPassword;
  final bool hasGoogle;

  bool get isWorker => role == UserRole.worker;

  bool get isEmployer => role == UserRole.employer;

  bool get hasIdentity => fullName.trim().isNotEmpty;

  bool get isOnboarded => hasIdentity && displayName.trim().isNotEmpty;

  bool get hasSkills => skills.isNotEmpty;

  bool get isProfileComplete =>
      isOnboarded &&
      district.isNotEmpty &&
      (isEmployer || hasSkills);

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  int get completeness {
    var score = 0;
    if (fullName.isNotEmpty) score += 20;
    if (displayName.isNotEmpty) score += 10;
    if (headline.isNotEmpty) score += 15;
    if (district.isNotEmpty) score += 15;
    if (skills.isNotEmpty) score += 20;
    if (bio.isNotEmpty) score += 10;
    if (experience.isNotEmpty) score += 10;
    return score;
  }

  Profile copyWith({
    String? fullName,
    String? displayName,
    String? headline,
    String? district,
    String? bio,
    List<String>? skills,
    List<Experience>? experience,
    UserRole? role,
    String? photoUrl,
    String? phone,
    double? maxDistanceKm,
    int? minPay,
    int? startHour,
    int? endHour,
  }) => Profile(
    id: id,
    fullName: fullName ?? this.fullName,
    displayName: displayName ?? this.displayName,
    headline: headline ?? this.headline,
    district: district ?? this.district,
    bio: bio ?? this.bio,
    skills: skills ?? this.skills,
    experience: experience ?? this.experience,
    role: role ?? this.role,
    photoUrl: photoUrl ?? this.photoUrl,
    createdAt: createdAt,
    email: email,
    phone: phone ?? this.phone,
    maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
    minPay: minPay ?? this.minPay,
    startHour: startHour ?? this.startHour,
    endHour: endHour ?? this.endHour,
    hasPassword: hasPassword,
    hasGoogle: hasGoogle,
  );

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String? ?? '',
    fullName: json['fullName'] as String? ?? '',
    displayName: json['displayName'] as String? ?? '',
    headline: json['headline'] as String? ?? '',
    district: json['district'] as String? ?? '',
    bio: json['bio'] as String? ?? '',
    skills: (json['skills'] as List?)?.cast<String>() ?? const <String>[],
    experience: [
      for (final item in (json['experience'] as List?) ?? const [])
        if (item is Map) Experience.fromJson(Map<String, dynamic>.from(item)),
    ],
    role: UserRoleX.parse(json['role'] as String?),
    photoUrl: json['photoUrl'] as String?,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    maxDistanceKm: (json['maxDistanceKm'] as num?)?.toDouble() ?? 5,
    minPay: (json['minPay'] as num?)?.toInt() ?? 50000,
    startHour: (json['startHour'] as num?)?.toInt() ?? 8,
    endHour: (json['endHour'] as num?)?.toInt() ?? 17,
    hasPassword: json['hasPassword'] as bool? ?? false,
    hasGoogle: json['hasGoogle'] as bool? ?? false,
  );
}

class PublicProfile {
  const PublicProfile({
    required this.id,
    required this.fullName,
    required this.displayName,
    this.headline = '',
    this.district = '',
    this.bio = '',
    this.skills = const [],
    this.experience = const [],
    this.role = UserRole.worker,
    this.photoUrl,
    this.openJobs = const [],
  });

  final String id;
  final String fullName;
  final String displayName;
  final String headline;
  final String district;
  final String bio;
  final List<String> skills;
  final List<Experience> experience;
  final UserRole role;
  final String? photoUrl;
  final List<OpenJob> openJobs;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  factory PublicProfile.fromJson(Map<String, dynamic> json) => PublicProfile(
    id: json['id'] as String? ?? '',
    fullName: json['fullName'] as String? ?? '',
    displayName: json['displayName'] as String? ?? '',
    headline: json['headline'] as String? ?? '',
    district: json['district'] as String? ?? '',
    bio: json['bio'] as String? ?? '',
    skills: (json['skills'] as List?)?.cast<String>() ?? const <String>[],
    experience: [
      for (final item in (json['experience'] as List?) ?? const [])
        if (item is Map) Experience.fromJson(Map<String, dynamic>.from(item)),
    ],
    role: UserRoleX.parse(json['role'] as String?),
    photoUrl: json['photoUrl'] as String?,
    openJobs: [
      for (final item in (json['openJobs'] as List?) ?? const [])
        if (item is Map) OpenJob.fromJson(Map<String, dynamic>.from(item)),
    ],
  );
}

class OpenJob {
  const OpenJob({
    required this.id,
    required this.title,
    required this.company,
    required this.pay,
    required this.payPeriod,
    required this.urgency,
    this.category = '',
    this.district = '',
  });

  final String id;
  final String title;
  final String company;
  final int pay;
  final String payPeriod;
  final JobUrgency urgency;
  final String category;
  final String district;

  factory OpenJob.fromJson(Map<String, dynamic> json) => OpenJob(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    company: json['company'] as String? ?? '',
    pay: (json['pay'] as num?)?.toInt() ?? 0,
    payPeriod: json['payPeriod'] as String? ?? '',
    urgency: JobUrgencyX.parse(json['urgency'] as String?),
    category: json['category'] as String? ?? '',
    district: json['district'] as String? ?? '',
  );
}

class PeopleCard {
  const PeopleCard({
    required this.profile,
    this.openJobs = 0,
  });

  final PublicProfile profile;
  final int openJobs;
}
