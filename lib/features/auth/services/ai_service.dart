import 'api_service.dart';

/// [role] vaut 'user' (l'utilisateur) ou 'model' (l'assistant).
class AiMessage {
  final String role;
  final String text;
  const AiMessage({required this.role, required this.text});

  bool get isUser => role == 'user';

  Map<String, dynamic> toJson() => {'role': role, 'text': text};
}

class AiService {
  final _api = ApiService();

  Future<String> sendMessage(List<AiMessage> history) async {
    final data = await _api.post('/ai/chat', {
      'messages': history.map((m) => m.toJson()).toList(),
    }, timeout: const Duration(seconds: 50));
    final reply = (data is Map) ? data['reply'] : null;
    return reply?.toString() ?? '';
  }
}
