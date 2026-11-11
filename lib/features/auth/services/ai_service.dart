import 'api_service.dart';

/// Un message de la conversation avec l'assistant.
/// [role] vaut 'user' (l'utilisateur) ou 'model' (l'assistant).
class AiMessage {
  final String role;
  final String text;
  const AiMessage({required this.role, required this.text});

  bool get isUser => role == 'user';

  Map<String, dynamic> toJson() => {'role': role, 'text': text};
}

/// Client de l'assistant santé IA (backend -> Google Gemini).
class AiService {
  final _api = ApiService();

  /// Envoie l'historique complet et renvoie la réponse de l'assistant.
  Future<String> sendMessage(List<AiMessage> history) async {
    final data = await _api.post('/ai/chat', {
      'messages': history.map((m) => m.toJson()).toList(),
    });
    final reply = (data is Map) ? data['reply'] : null;
    return reply?.toString() ?? '';
  }
}
