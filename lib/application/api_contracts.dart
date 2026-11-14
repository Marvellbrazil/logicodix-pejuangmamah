import '../domain/chat.dart';
import '../domain/job.dart';
import '../domain/profile.dart';

class Session {
  const Session({required this.token, required this.profile});

  final String token;
  final Profile profile;
}

class ProfileStats {
  const ProfileStats({
    this.applications = 0,
    this.jobs = 0,
    this.chats = 0,
  });

  final int applications;
  final int jobs;
  final int chats;

  factory ProfileStats.fromJson(Map<String, dynamic>? json) => ProfileStats(
    applications: (json?['applications'] as num?)?.toInt() ?? 0,
    jobs: (json?['jobs'] as num?)?.toInt() ?? 0,
    chats: (json?['chats'] as num?)?.toInt() ?? 0,
  );
}

abstract interface class AuthApi {
  Future<Session> register({
    required String email,
    required String password,
    required String fullName,
    required String displayName,
    required UserRole role,
  });

  Future<Session> login({required String email, required String password});

  Future<Session> googleSignIn({
    required String idToken,
    required UserRole role,
  });

  Future<Profile> currentUser(String token);

  Future<void> logout();
}

abstract interface class ProfileApi {
  Future<(Profile, ProfileStats)> me(String token);

  Future<Profile> update(String token, ProfilePatch patch);

  Future<PublicProfile> user(String token, String id);

  Future<List<PeopleCard>> people(String token, {String q, UserRole? role});
}

class ProfilePatch {
  const ProfilePatch({
    this.fullName,
    this.displayName,
    this.headline,
    this.district,
    this.bio,
    this.skills,
    this.experience,
    this.role,
    this.maxDistanceKm,
    this.minPay,
    this.startHour,
    this.endHour,
    this.phone,
  });

  final String? fullName;
  final String? displayName;
  final String? headline;
  final String? district;
  final String? bio;
  final List<String>? skills;
  final List<Experience>? experience;
  final UserRole? role;
  final double? maxDistanceKm;
  final int? minPay;
  final int? startHour;
  final int? endHour;
  final String? phone;

  Map<String, Object?> toJson() => {
    if (fullName != null) 'fullName': fullName,
    if (displayName != null) 'displayName': displayName,
    if (headline != null) 'headline': headline,
    if (district != null) 'district': district,
    if (bio != null) 'bio': bio,
    if (skills != null) 'skills': skills,
    if (experience != null)
      'experience': [for (final item in experience!) item.toJson()],
    if (role != null) 'role': role!.wire,
    if (maxDistanceKm != null) 'maxDistanceKm': maxDistanceKm,
    if (minPay != null) 'minPay': minPay,
    if (startHour != null) 'startHour': startHour,
    if (endHour != null) 'endHour': endHour,
    if (phone != null) 'phone': phone,
  };
}

class JobFeed {
  const JobFeed({required this.jobs, required this.categories});

  final List<Job> jobs;
  final List<String> categories;
}

class NewJob {
  const NewJob({
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
    this.skills = const [],
    this.contact = '',
  });

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
  final List<String> skills;
  final String contact;

  Map<String, Object?> toJson() => {
    'title': title,
    'company': company,
    'category': category,
    'description': description,
    'pay': pay,
    'payPeriod': payPeriod,
    'district': district,
    'distanceKm': distanceKm,
    'startHour': startHour,
    'endHour': endHour,
    'urgency': urgency.wire,
    'skills': skills,
    'contact': contact,
  };
}

abstract interface class JobApi {
  Future<JobFeed> feed(
    String token, {
    String q = '',
    String category = '',
    JobUrgency? urgency,
    bool mine = false,
  });

  Future<Job> job(String token, String id);

  Future<Job> create(String token, NewJob job);

  Future<Job> setFilled(String token, String id, bool filled);

  Future<void> delete(String token, String id);

  Future<(Job, List<Applicant>)> applicants(String token, String jobId);
}

abstract interface class ApplicationApi {
  Future<List<Application>> mine(String token);

  Future<List<Application>> inbox(String token);

  Future<(Application, String?)> apply(String token, String jobId);

  Future<Application> setStatus(
    String token,
    String applicationId,
    ApplicationStatus status,
  );
}

abstract interface class ChatApi {
  Future<(List<ChatSummary>, int)> list(String token);

  Future<(ChatSummary?, List<ChatMessage>)> messages(
    String token,
    String chatId,
  );

  Future<ChatMessage> send(String token, String chatId, String body);

  Future<void> markRead(String token, String chatId);
}

abstract interface class TokenStore {
  Future<String?> read();

  Future<void> write(String token);

  Future<void> clear();
}
