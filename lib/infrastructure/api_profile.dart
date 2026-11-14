import '../application/api_contracts.dart';
import '../domain/profile.dart';
import 'api_client.dart';

class ApiProfile implements ProfileApi {
  ApiProfile(this._client);

  final ApiClient _client;

  @override
  Future<(Profile, ProfileStats)> me(String token) async {
    _client.setToken(token);
    final json = await _client.get('/api/me');
    return (
      Profile.fromJson(Map<String, dynamic>.from(json['user'] as Map? ?? const {})),
      ProfileStats.fromJson(
        json['stats'] as Map<String, dynamic>?,
      ),
    );
  }

  @override
  Future<Profile> update(String token, ProfilePatch patch) async {
    _client.setToken(token);
    final json = await _client.patch('/api/me', body: patch.toJson());
    return Profile.fromJson(
      Map<String, dynamic>.from(json['user'] as Map? ?? const {}),
    );
  }

  @override
  Future<PublicProfile> user(String token, String id) async {
    _client.setToken(token);
    final json = await _client.get('/api/users/$id');
    return PublicProfile.fromJson({
      ...Map<String, dynamic>.from(json['user'] as Map? ?? const {}),
      'openJobs': json['openJobs'],
    });
  }

  @override
  Future<List<PeopleCard>> people(
    String token, {
    String q = '',
    UserRole? role,
  }) async {
    _client.setToken(token);
    final json = await _client.get(
      '/api/users',
      query: {'q': q, if (role != null) 'role': role.wire},
    );
    return [
      for (final item in (json['people'] as List?) ?? const [])
        if (item is Map)
          PeopleCard(
            profile: PublicProfile.fromJson(Map<String, dynamic>.from(item)),
            openJobs: (item['openJobs'] as num?)?.toInt() ?? 0,
          ),
    ];
  }
}
