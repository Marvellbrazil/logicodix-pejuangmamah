import 'job.dart';

class Counterpart {
  const Counterpart({
    required this.id,
    required this.fullName,
    required this.displayName,
    this.photoUrl,
  });

  final String id;
  final String fullName;
  final String displayName;
  final String? photoUrl;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  factory Counterpart.fromJson(Map<String, dynamic> json) => Counterpart(
    id: json['id'] as String? ?? '',
    fullName: json['fullName'] as String? ?? '',
    displayName: json['displayName'] as String? ?? '',
    photoUrl: json['photoUrl'] as String?,
  );
}

class ChatSummary {
  const ChatSummary({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.company,
    required this.counterpart,
    required this.lastMessageAt,
    this.lastMessage = '',
    this.lastSenderId = '',
    this.unread = 0,
    this.applicationId = '',
  });

  final String id;
  final String jobId;
  final String jobTitle;
  final String company;
  final Counterpart counterpart;
  final DateTime lastMessageAt;
  final String lastMessage;
  final String lastSenderId;
  final int unread;
  final String applicationId;

  factory ChatSummary.fromJson(Map<String, dynamic> json) => ChatSummary(
    id: json['id'] as String? ?? '',
    jobId: json['jobId'] as String? ?? '',
    jobTitle: json['jobTitle'] as String? ?? '',
    company: json['company'] as String? ?? '',
    counterpart: Counterpart.fromJson(
      Map<String, dynamic>.from(json['counterpart'] as Map? ?? const {}),
    ),
    lastMessageAt:
        DateTime.tryParse(json['lastMessageAt'] as String? ?? '') ??
        DateTime.now(),
    lastMessage: json['lastMessage'] as String? ?? '',
    lastSenderId: json['lastSenderId'] as String? ?? '',
    unread: (json['unread'] as num?)?.toInt() ?? 0,
    applicationId: json['applicationId'] as String? ?? '',
  );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.body,
    required this.createdAt,
    required this.mine,
  });

  final String id;
  final String senderId;
  final String body;
  final DateTime createdAt;
  final bool mine;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String? ?? '',
    senderId: json['senderId'] as String? ?? '',
    body: json['body'] as String? ?? '',
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    mine: json['mine'] as bool? ?? false,
  );
}

class Application {
  const Application({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.jobId,
    required this.jobTitle,
    required this.company,
    required this.pay,
    required this.payPeriod,
    required this.district,
    required this.urgency,
    required this.employerId,
    required this.employerName,
    required this.employerDisplayName,
    this.employerPhotoUrl,
    this.chatId,
    this.filled = false,
    this.category = '',
    this.note = '',
  });

  final String id;
  final ApplicationStatus status;
  final DateTime createdAt;
  final String jobId;
  final String jobTitle;
  final String company;
  final int pay;
  final String payPeriod;
  final String district;
  final JobUrgency urgency;
  final String employerId;
  final String employerName;
  final String employerDisplayName;
  final String? employerPhotoUrl;
  final String? chatId;
  final bool filled;
  final String category;
  final String note;

  factory Application.fromJson(Map<String, dynamic> json) {
    final job = Map<String, dynamic>.from(json['job'] as Map? ?? const {});
    return Application(
      id: json['id'] as String? ?? '',
      status: ApplicationStatusX.parse(json['status'] as String?),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      jobId: job['id'] as String? ?? '',
      jobTitle: job['title'] as String? ?? '',
      company: job['company'] as String? ?? '',
      pay: (job['pay'] as num?)?.toInt() ?? 0,
      payPeriod: job['payPeriod'] as String? ?? '',
      district: job['district'] as String? ?? '',
      urgency: JobUrgencyX.parse(job['urgency'] as String?),
      employerId: job['employerId'] as String? ?? '',
      employerName: job['employerName'] as String? ?? '',
      employerDisplayName: job['employerDisplayName'] as String? ?? '',
      employerPhotoUrl: job['employerPhotoUrl'] as String?,
      chatId: json['chatId'] as String?,
      filled: job['filled'] as bool? ?? false,
      category: job['category'] as String? ?? '',
      note: json['note'] as String? ?? '',
    );
  }
}

class Applicant {
  const Applicant({
    required this.applicationId,
    required this.status,
    required this.createdAt,
    required this.workerId,
    required this.fullName,
    required this.displayName,
    required this.headline,
    required this.district,
    required this.email,
    required this.phone,
    this.photoUrl,
    this.skills = const [],
  });

  final String applicationId;
  final ApplicationStatus status;
  final DateTime createdAt;
  final String workerId;
  final String fullName;
  final String displayName;
  final String headline;
  final String district;
  final String email;
  final String phone;
  final String? photoUrl;
  final List<String> skills;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  factory Applicant.fromJson(Map<String, dynamic> json) {
    final worker = Map<String, dynamic>.from(json['worker'] as Map? ?? const {});
    return Applicant(
      applicationId: json['id'] as String? ?? '',
      status: ApplicationStatusX.parse(json['status'] as String?),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      workerId: worker['id'] as String? ?? '',
      fullName: worker['fullName'] as String? ?? '',
      displayName: worker['displayName'] as String? ?? '',
      headline: worker['headline'] as String? ?? '',
      district: worker['district'] as String? ?? '',
      email: worker['email'] as String? ?? '',
      phone: worker['phone'] as String? ?? '',
      photoUrl: worker['photoUrl'] as String?,
      skills: (worker['skills'] as List?)?.cast<String>() ?? const <String>[],
    );
  }
}
