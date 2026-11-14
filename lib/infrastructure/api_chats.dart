import '../application/api_contracts.dart';
import '../domain/chat.dart';
import 'api_client.dart';

class ApiChats implements ChatApi {
  ApiChats(this._client);

  final ApiClient _client;

  @override
  Future<(List<ChatSummary>, int)> list(String token) async {
    _client.setToken(token);
    final json = await _client.get('/api/chats');
    return (
      [
        for (final item in (json['chats'] as List?) ?? const [])
          if (item is Map) ChatSummary.fromJson(Map<String, dynamic>.from(item)),
      ],
      (json['unread'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<(ChatSummary?, List<ChatMessage>)> messages(
    String token,
    String chatId,
  ) async {
    _client.setToken(token);
    final json = await _client.get('/api/chats/$chatId/messages');
    return (
      json['chat'] is Map
          ? ChatSummary.fromJson(
              Map<String, dynamic>.from(json['chat'] as Map),
            )
          : null,
      [
        for (final item in (json['messages'] as List?) ?? const [])
          if (item is Map) ChatMessage.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }

  @override
  Future<ChatMessage> send(String token, String chatId, String body) async {
    _client.setToken(token);
    final json = await _client.post(
      '/api/chats/$chatId/messages',
      body: {'body': body},
    );
    return ChatMessage.fromJson(
      Map<String, dynamic>.from(json['message'] as Map? ?? const {}),
    );
  }

  @override
  Future<void> markRead(String token, String chatId) async {
    _client.setToken(token);
    await _client.post('/api/chats/$chatId/read');
  }
}
