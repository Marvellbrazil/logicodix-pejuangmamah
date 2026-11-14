abstract interface class AssistantGateway {
  Future<String> reply({
    required String systemPrompt,
    required List<(String role, String text)> history,
  });

  bool get available;
}

class AssistantUnavailable implements Exception {
  const AssistantUnavailable(this.message);

  final String message;

  @override
  String toString() => 'AssistantUnavailable: $message';
}
