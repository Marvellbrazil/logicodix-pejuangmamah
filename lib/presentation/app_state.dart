import 'package:flutter/foundation.dart';

import '../application/api_contracts.dart';
import '../application/api_failure.dart';
import '../domain/chat.dart';
import '../domain/job.dart';
import '../domain/match.dart';
import '../domain/profile.dart';
import '../infrastructure/api_client.dart';

class AppState extends ChangeNotifier {
  // ignore: prefer_initializing_formals
  AppState({
    required ApiClient client,
    required AuthApi auth,
    required ProfileApi profiles,
    required JobApi jobs,
    required ApplicationApi applications,
    required ChatApi chats,
    required TokenStore tokens,
  }) : _client = client,
       _auth = auth,
       _profiles = profiles,
       _jobs = jobs,
       _applications = applications,
       _chats = chats,
       _tokens = tokens;

  final ApiClient _client;
  final AuthApi _auth;
  final ProfileApi _profiles;
  final JobApi _jobs;
  final ApplicationApi _applications;
  final ChatApi _chats;
  final TokenStore _tokens;

  String? _token;
  Profile? _profile;
  ProfileStats _stats = const ProfileStats();
  List<Job> _feed = const [];
  List<String> _categories = const [];
  List<Application> _myApplications = const [];
  List<Application> _inbox = const [];
  List<ChatSummary> _chatList = const [];
  int _unreadChats = 0;
  bool _booting = true;
  bool _busy = false;
  String? _authError;
  String? _feedError;
  int _tabIndex = 0;

  bool get booting => _booting;
  bool get busy => _busy;
  String? get authError => _authError;
  String? get feedError => _feedError;
  Profile? get profile => _profile;
  ProfileStats get stats => _stats;
  List<Job> get feed => _feed;
  List<String> get categories => _categories;
  List<Application> get myApplications => _myApplications;
  List<Application> get inbox => _inbox;
  List<ChatSummary> get chats => _chatList;
  int get unreadChats => _unreadChats;
  int get tabIndex => _tabIndex;
  bool get signedIn => _token != null && _profile != null;
  String get token => _token ?? '';

  bool get needsOnboarding =>
      _profile != null && !_profile!.isProfileComplete;

  List<Match> get ranked {
    final current = _profile;
    if (current == null) return const [];
    return Match.rank(_feed, current);
  }

  List<Match> get rankedToday {
    final today = ranked
        .where((m) => m.job.urgency == JobUrgency.today)
        .toList();
    return today.isEmpty ? ranked.take(3).toList() : today;
  }

  List<Match> get employerJobs {
    final current = _profile;
    if (current == null) return const [];
    return Match.rank(_feed, current, includeFilled: true);
  }

  void selectTab(int index) {
    if (_tabIndex == index) return;
    _tabIndex = index;
    notifyListeners();
  }

  Future<void> boot() async {
    _booting = true;
    notifyListeners();
    try {
      final stored = await _tokens.read();
      if (stored != null && stored.isNotEmpty) {
        _token = stored;
        _client.setToken(stored);
        try {
          final (profile, stats) = await _profiles.me(stored);
          _profile = profile;
          _stats = stats;
        } on ApiFailure catch (error) {
          if (error.isUnauthorized) {
            await _clearSession();
          } else {
            _authError = error.message;
          }
        }
      }
    } catch (error) {
      _authError = 'Gagal membaca sesi tersimpan.';
    } finally {
      _booting = false;
      notifyListeners();
    }
    if (signedIn) {
      await Future.wait([refreshFeed(), refreshApplications(), refreshChats()]);
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String displayName,
    required UserRole role,
  }) => _runAuth(
    () => _auth.register(
      email: email,
      password: password,
      fullName: fullName,
      displayName: displayName,
      role: role,
    ),
  );

  Future<bool> login({required String email, required String password}) =>
      _runAuth(() => _auth.login(email: email, password: password));

  Future<bool> signInWithGoogle({
    required String idToken,
    required UserRole role,
  }) => _runAuth(() => _auth.googleSignIn(idToken: idToken, role: role));

  Future<bool> _runAuth(Future<Session> Function() action) async {
    if (_busy) return false;
    _busy = true;
    _authError = null;
    notifyListeners();
    try {
      final session = await action();
      _token = session.token;
      _profile = session.profile;
      _client.setToken(session.token);
      await _tokens.write(session.token);
      _tabIndex = 0;
      await Future.wait([
        refreshProfile(),
        refreshFeed(),
        refreshApplications(),
        refreshChats(),
      ]);
      return true;
    } on ApiFailure catch (error) {
      _authError = error.message;
      return false;
    } catch (_) {
      _authError = 'Terjadi kesalahan tak terduga. Coba lagi.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _busy = true;
    notifyListeners();
    try {
      await _auth.logout();
      await _clearSession();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _clearSession() async {
    _token = null;
    _profile = null;
    _stats = const ProfileStats();
    _feed = const [];
    _categories = const [];
    _myApplications = const [];
    _inbox = const [];
    _chatList = const [];
    _unreadChats = 0;
    _client.setToken(null);
    await _tokens.clear();
  }

  Future<void> refreshProfile() async {
    final token = _token;
    if (token == null) return;
    try {
      final (profile, stats) = await _profiles.me(token);
      _profile = profile;
      _stats = stats;
      notifyListeners();
    } on ApiFailure catch (error) {
      if (error.isUnauthorized) {
        await _clearSession();
        notifyListeners();
      }
    }
  }

  Future<void> refreshFeed({
    String q = '',
    String category = '',
    JobUrgency? urgency,
    bool mine = false,
  }) async {
    final token = _token;
    if (token == null) return;
    try {
      final feed = await _jobs.feed(
        token,
        q: q,
        category: category,
        urgency: urgency,
        mine: mine,
      );
      _feed = feed.jobs;
      _categories = feed.categories;
      _feedError = null;
      notifyListeners();
    } on ApiFailure catch (error) {
      _feedError = error.message;
      notifyListeners();
    }
  }

  Future<void> refreshApplications() async {
    final token = _token;
    if (token == null) return;
    try {
      final isEmployer = _profile?.isEmployer ?? false;
      if (isEmployer) {
        _inbox = await _applications.inbox(token);
      } else {
        _myApplications = await _applications.mine(token);
      }
      notifyListeners();
    } on ApiFailure catch (_) {
      return;
    }
  }

  Future<void> refreshChats() async {
    final token = _token;
    if (token == null) return;
    try {
      final (list, unread) = await _chats.list(token);
      _chatList = list;
      _unreadChats = unread;
      notifyListeners();
    } on ApiFailure catch (_) {
      return;
    }
  }

  Future<(Profile, ProfileStats)> updateProfile(ProfilePatch patch) async {
    final token = _token;
    if (token == null) throw const ApiFailure('Sesi berakhir.');
    final profile = await _profiles.update(token, patch);
    _profile = profile;
    notifyListeners();
    await refreshApplications();
    return (profile, _stats);
  }

  Future<PublicProfile> fetchPerson(String id) => _profiles.user(token, id);

  Future<List<PeopleCard>> searchPeople({
    String q = '',
    UserRole? role,
  }) => _profiles.people(token, q: q, role: role);

  Future<Job> fetchJob(String id) => _jobs.job(token, id);

  Future<List<Job>> searchJobs(String query) async {
    final feed = await _jobs.feed(token, q: query);
    return feed.jobs;
  }

  Future<Job> postJob(NewJob job) async {
    final created = await _jobs.create(token, job);
    await refreshFeed(mine: true);
    await refreshProfile();
    return created;
  }

  Future<void> setJobFilled(String id, bool filled) async {
    final updated = await _jobs.setFilled(token, id, filled);
    _feed = [
      for (final job in _feed) if (job.id == id) updated else job,
    ];
    notifyListeners();
    await refreshProfile();
  }

  Future<void> deleteJob(String id) async {
    await _jobs.delete(token, id);
    _feed = _feed.where((job) => job.id != id).toList();
    notifyListeners();
    await refreshProfile();
  }

  Future<(Job, List<Applicant>)> jobApplicants(String id) =>
      _jobs.applicants(token, id);

  Future<Application> apply(String jobId) async {
    final (application, _) = await _applications.apply(token, jobId);
    _feed = [
      for (final job in _feed)
        if (job.id == jobId)
          job.copyWith(
            applicationId: application.id,
            applicationStatus: application.status,
          )
        else
          job,
    ];
    await refreshApplications();
    await refreshChats();
    notifyListeners();
    return application;
  }

  Future<void> updateApplication(
    String applicationId,
    ApplicationStatus status,
  ) async {
    final updated = await _applications.setStatus(
      token,
      applicationId,
      status,
    );
    _myApplications = [
      for (final item in _myApplications)
        if (item.id == applicationId) updated else item,
    ];
    _inbox = [
      for (final item in _inbox)
        if (item.id == applicationId) updated else item,
    ];
    notifyListeners();
    await refreshFeed();
    await refreshProfile();
  }

  Future<int> messageCount(String chatId) async {
    final (_, messages) = await _chats.messages(token, chatId);
    return messages.length;
  }

  Future<(ChatSummary?, List<ChatMessage>)> openChat(String chatId) =>
      _chats.messages(token, chatId);

  Future<ChatMessage> sendMessage(String chatId, String body) async {
    final message = await _chats.send(token, chatId, body);
    await refreshChats();
    return message;
  }

  Future<void> markChatRead(String chatId) async {
    await _chats.markRead(token, chatId);
    await refreshChats();
  }
}
