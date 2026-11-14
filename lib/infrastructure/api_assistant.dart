import '../application/assistant_gateway.dart';
import 'api_client.dart';

class ApiAssistantGateway implements AssistantGateway {
  ApiAssistantGateway(this._client);

  final ApiClient _client;

  @override
  bool get available => _client.hasToken;

  @override
  Future<String> reply({
    required String systemPrompt,
    required List<(String role, String text)> history,
  }) async {
    final json = await _client.post(
      '/api/assistant',
      body: {
        'system': systemPrompt,
        'messages': [
          for (final (role, text) in history)
            {'role': role == 'assistant' ? 'assistant' : role, 'text': text},
        ],
      },
    );
    final reply = (json['reply'] as String? ?? '').trim();
    if (reply.isEmpty) {
      throw const AssistantUnavailable('Asisten mengirim balasan kosong.');
    }
    return reply;
  }
}
