import 'package:flutter/material.dart';

import '../services/ai_service.dart';
import '../services/api_service.dart';

const _kPrimary = Color(0xFF00685D);
const _kSurface = Color(0xFFF5F7FA);
const _kTextPrimary = Color(0xFF1D3557);
const _kTextSecondary = Color(0xFF6C757D);

/// Module user — Assistant santé IA (Google Gemini via le backend).
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _service = AiService();
  final _inputCtl = TextEditingController();
  final _scrollCtl = ScrollController();
  final _focus = FocusNode();

  final List<AiMessage> _messages = [
    const AiMessage(
      role: 'model',
      text:
          "Hi, I'm MediTrack AI, your health assistant. Ask me anything about "
          "your health, medications or wellbeing.",
    ),
  ];
  bool _sending = false;

  static const _suggestions = [
    'How can I improve my sleep?',
    'What makes a balanced diet?',
    'Tips to stay hydrated',
  ];

  @override
  void dispose() {
    _inputCtl.dispose();
    _scrollCtl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtl.hasClients) return;
      _scrollCtl.animateTo(
        _scrollCtl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _inputCtl.text).trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(AiMessage(role: 'user', text: text));
      _sending = true;
    });
    _inputCtl.clear();
    _scrollToBottom();

    try {
      final reply = await _service.sendMessage(_messages);
      if (!mounted) return;
      setState(() {
        _messages.add(AiMessage(role: 'model', text: reply));
        _sending = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(AiMessage(
          role: 'model',
          text: 'Sorry, something went wrong: ${e.message}',
        ));
        _sending = false;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final showSuggestions = _messages.length <= 1 && !_sending;

    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kTextPrimary,
        titleSpacing: 12,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'MediTrack AI',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const _DisclaimerBanner(),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtl,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length + (_sending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) return const _TypingBubble();
                return _MessageBubble(message: _messages[index]);
              },
            ),
          ),
          if (showSuggestions) _Suggestions(onTap: _send),
          _InputBar(
            controller: _inputCtl,
            focusNode: _focus,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bandeau de précaution (l'assistant ne remplace pas un médecin)
// ---------------------------------------------------------------------------

class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF4E5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: Color(0xFF9A5B00)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'General information only — not a medical diagnosis. '
              'Always consult a healthcare professional.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: Color(0xFF7A4A00),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bulles de conversation
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  final AiMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isUser ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D1D3557),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              const Icon(Icons.auto_awesome, size: 16, color: _kPrimary),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: SelectableText(
                message.text,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: isUser ? Colors.white : _kTextPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: _TypingIndicator(),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1D3557),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _ctl,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final t = (_ctl.value * 3 - i).clamp(0.0, 1.0);
              final opacity = 0.3 + 0.7 * (t < 0.5 ? t * 2 : (1 - t) * 2);
              return Padding(
                padding: EdgeInsets.only(right: i == 2 ? 0 : 6),
                child: Opacity(
                  opacity: opacity.clamp(0.3, 1.0),
                  child: const CircleAvatar(radius: 4, backgroundColor: _kPrimary),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Suggestions de démarrage
// ---------------------------------------------------------------------------

class _Suggestions extends StatelessWidget {
  final void Function(String) onTap;
  const _Suggestions({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final s in _AiAssistantScreenState._suggestions)
            ActionChip(
              label: Text(s),
              labelStyle:
                  const TextStyle(fontSize: 13, color: _kTextPrimary),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFD5E7E4)),
              onPressed: () => onTap(s),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Barre de saisie
// ---------------------------------------------------------------------------

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: const TextStyle(fontSize: 15, color: _kTextPrimary),
              decoration: InputDecoration(
                hintText: 'Ask a health question...',
                hintStyle: const TextStyle(color: _kTextSecondary),
                filled: true,
                fillColor: _kSurface,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            height: 48,
            child: Material(
              color: sending ? _kPrimary.withValues(alpha: 0.5) : _kPrimary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: sending ? null : onSend,
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
