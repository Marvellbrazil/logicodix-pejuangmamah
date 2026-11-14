import '../application/api_contracts.dart';
import '../domain/chat.dart';
import '../domain/job.dart';
import 'api_client.dart';

class ApiJobs implements JobApi, ApplicationApi {
  ApiJobs(this._client);

  final ApiClient _client;

  @override
  Future<JobFeed> feed(
    String token, {
    String q = '',
    String category = '',
    JobUrgency? urgency,
    bool mine = false,
  }) async {
    _client.setToken(token);
    final json = await _client.get(
      '/api/jobs',
      query: {
        'q': q,
        'category': category,
        if (urgency != null) 'urgency': urgency.wire,
        if (mine) 'mine': 'true',
      },
    );
    return JobFeed(
      jobs: [
        for (final item in (json['jobs'] as List?) ?? const [])
          if (item is Map) Job.fromJson(Map<String, dynamic>.from(item)),
      ],
      categories:
          (json['categories'] as List?)?.cast<String>() ?? const <String>[],
    );
  }

  @override
  Future<Job> job(String token, String id) async {
    _client.setToken(token);
    final json = await _client.get('/api/jobs/$id');
    return Job.fromJson(
      Map<String, dynamic>.from(json['job'] as Map? ?? const {}),
    );
  }

  @override
  Future<Job> create(String token, NewJob job) async {
    _client.setToken(token);
    final json = await _client.post('/api/jobs', body: job.toJson());
    return Job.fromJson(
      Map<String, dynamic>.from(json['job'] as Map? ?? const {}),
    );
  }

  @override
  Future<Job> setFilled(String token, String id, bool filled) async {
    _client.setToken(token);
    final json = await _client.patch(
      '/api/jobs/$id',
      body: {'filled': filled},
    );
    return Job.fromJson(
      Map<String, dynamic>.from(json['job'] as Map? ?? const {}),
    );
  }

  @override
  Future<void> delete(String token, String id) async {
    _client.setToken(token);
    await _client.delete('/api/jobs/$id');
  }

  @override
  Future<(Job, List<Applicant>)> applicants(String token, String jobId) async {
    _client.setToken(token);
    final json = await _client.get('/api/jobs/$jobId/applicants');
    return (
      Job.fromJson(Map<String, dynamic>.from(json['job'] as Map? ?? const {})),
      [
        for (final item in (json['applicants'] as List?) ?? const [])
          if (item is Map) Applicant.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }

  @override
  Future<List<Application>> mine(String token) async {
    _client.setToken(token);
    final json = await _client.get('/api/applications/mine');
    return [
      for (final item in (json['applications'] as List?) ?? const [])
        if (item is Map) Application.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  @override
  Future<List<Application>> inbox(String token) async {
    _client.setToken(token);
    final json = await _client.get('/api/applications/inbox');
    return [
      for (final item in (json['applications'] as List?) ?? const [])
        if (item is Map) Application.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  @override
  Future<(Application, String?)> apply(String token, String jobId) async {
    _client.setToken(token);
    final json = await _client.post('/api/jobs/$jobId/apply');
    return (
      Application.fromJson(
        Map<String, dynamic>.from(json['application'] as Map? ?? const {}),
      ),
      json['chatId'] as String?,
    );
  }

  @override
  Future<Application> setStatus(
    String token,
    String applicationId,
    ApplicationStatus status,
  ) async {
    _client.setToken(token);
    final json = await _client.patch(
      '/api/applications/$applicationId',
      body: {'status': status.wire},
    );
    return Application.fromJson(
      Map<String, dynamic>.from(json['application'] as Map? ?? const {}),
    );
  }
}
