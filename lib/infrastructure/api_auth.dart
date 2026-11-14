import '../application/api_contracts.dart';
import '../domain/profile.dart';
import 'api_client.dart';

class ApiAuth implements AuthApi {
  ApiAuth(this._client, {this.googleIdTokenProvider});

  final ApiClient _client;
  final Future<String?> Function()? googleIdTokenProvider;

  Session _session(Map<String, dynamic> json) {
    final token = json['token'] as String? ?? '';
    _client.setToken(token);
    return Session(
      token: token,
      profile: Profile.fromJson(
        Map<String, dynamic>.from(json['user'] as Map? ?? const {}),
      ),
    );
  }

  @override
  Future<Session> register({
    required String email,
    required String password,
    required String fullName,
    required String displayName,
    required UserRole role,
  }) async {
    final json = await _client.post(
      '/api/auth/register',
      authenticated: false,
      body: {
        'email': email.trim(),
        'password': password,
        'fullName': fullName.trim(),
        'displayName': displayName.trim(),
        'role': role.wire,
      },
    );
    return _session(json);
  }

  @override
  Future<Session> login({
    required String email,
    required String password,
  }) async {
    final json = await _client.post(
      '/api/auth/login',
      authenticated: false,
      body: {'email': email.trim(), 'password': password},
    );
    return _session(json);
  }

  @override
  Future<Session> googleSignIn({
    required String idToken,
    required UserRole role,
  }) async {
    final json = await _client.post(
      '/api/auth/google',
      authenticated: false,
      body: {'idToken': idToken, 'role': role.wire},
    );
    return _session(json);
  }

  @override
  Future<Profile> currentUser(String token) async {
    _client.setToken(token);
    final json = await _client.get('/api/auth/me');
    return Profile.fromJson(
      Map<String, dynamic>.from(json['user'] as Map? ?? const {}),
    );
  }

  @override
  Future<void> logout() async {
    _client.setToken(null);
  }
}
