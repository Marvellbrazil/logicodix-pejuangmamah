import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../application/api_failure.dart';

class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  final Duration timeout;

  String? _token;

  bool get hasToken => _token != null && _token!.isNotEmpty;

  void setToken(String? token) {
    _token = (token == null || token.isEmpty) ? null : token;
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
    bool authenticated = true,
  }) => _send('GET', path, query: query, authenticated: authenticated);

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    bool authenticated = true,
  }) => _send('POST', path, body: body, authenticated: authenticated);

  Future<Map<String, dynamic>> patch(
    String path, {
    Object? body,
    bool authenticated = true,
  }) => _send('PATCH', path, body: body, authenticated: authenticated);

  Future<Map<String, dynamic>> delete(
    String path, {
    bool authenticated = true,
  }) => _send('DELETE', path, authenticated: authenticated);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool authenticated = true,
    bool allowRetry = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: query == null || query.isEmpty
          ? null
          : {
              for (final entry in query.entries)
                if (entry.value.isNotEmpty) entry.key: entry.value,
            },
    );

    final headers = <String, String>{
      'accept': 'application/json',
      if (body != null) 'content-type': 'application/json',
      if (authenticated && hasToken) 'authorization': 'Bearer $_token',
    };

    http.Response response;
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _client.send(request).timeout(timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const ApiFailure(
        'Server terlalu lama menjawab. Periksa jaringanmu.',
        code: 'timeout',
      );
    } catch (_) {
      throw const ApiFailure(
        'Tidak bisa terhubung ke server. Periksa jaringanmu.',
        code: 'offline',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return const {};
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
    }

    if (method == 'GET' && allowRetry && response.statusCode >= 500) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return _send(
        method,
        path,
        query: query,
        body: body,
        authenticated: authenticated,
        allowRetry: false,
      );
    }

    throw _failure(response);
  }

  ApiFailure _failure(http.Response response) {
    String message = 'Permintaan gagal (${response.statusCode}).';
    String code = 'http_${response.statusCode}';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] is Map) {
        final error = decoded['error'] as Map;
        message = error['message'] as String? ?? message;
        code = error['code'] as String? ?? code;
      }
    } catch (_) {
      if (response.statusCode >= 500) {
        message = 'Server sedang bermasalah. Coba lagi sebentar.';
      }
    }
    return ApiFailure(message, code: code, status: response.statusCode);
  }

  void close() => _client.close();
}
