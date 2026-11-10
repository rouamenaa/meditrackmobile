import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/daily_motivation.dart';
import '../services/motivation_service.dart';

/// Carte moderne « Conseil & Motivation du Jour »
/// Consomme l'API externe ZenQuotes pour dynamiser l'accueil du module Sport-Santé.
class DailyMotivationCard extends StatefulWidget {
  final VoidCallback? onQuoteChanged;

  const DailyMotivationCard({super.key, this.onQuoteChanged});

  @override
  State<DailyMotivationCard> createState() => _DailyMotivationCardState();
}

class _DailyMotivationCardState extends State<DailyMotivationCard> {
  final _service = MotivationService.instance;
  DailyMotivation? _motivation;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMotivation(forceRefresh: false);
  }

  Future<void> _fetchMotivation({required bool forceRefresh}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _service.getDailyMotivation(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _motivation = result;
        _isLoading = false;
      });
      widget.onQuoteChanged?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Impossible de charger la citation pour le moment.';
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(DailyMotivation motivation) {
    final text = '« ${motivation.quote} » — ${motivation.author} (via MediTrack)';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Citation copiée dans le presse-papiers'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF0B6B5D),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const kNavy = Color(0xFF0A2540);
    const kTeal = Color(0xFF0B6B5D);
    const kSoftTeal = Color(0xFFE8F5F1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kTeal.withValues(alpha: 0.18), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: kNavy.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                kSoftTeal.withValues(alpha: 0.4),
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. En-tête : Titre, badge et boutons d'action
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: kTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.format_quote_rounded,
                      color: kTeal,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Conseil & Motivation du Jour',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: kNavy,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (_motivation?.isFromApi ?? false)
                                    ? Colors.green
                                    : kTeal,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _motivation?.category ?? 'Bien-être & Persévérance',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_motivation != null && !_isLoading) ...[
                    IconButton(
                      icon: const Icon(Icons.content_copy_rounded, size: 18),
                      color: Colors.grey.shade600,
                      tooltip: 'Copier la citation',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _copyToClipboard(_motivation!),
                    ),
                  ],
                  IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: kTeal,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded, size: 20),
                    color: kTeal,
                    tooltip: 'Nouvelle inspiration',
                    visualDensity: VisualDensity.compact,
                    onPressed: _isLoading
                        ? null
                        : () => _fetchMotivation(forceRefresh: true),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 2. Corps de la citation
              if (_isLoading && _motivation == null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kTeal,
                      ),
                    ),
                  ),
                ),
              ] else if (_errorMessage != null && _motivation == null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _fetchMotivation(forceRefresh: true),
                        child: const Text('Réessayer', style: TextStyle(color: kTeal)),
                      ),
                    ],
                  ),
                ),
              ] else if (_motivation != null) ...[
                Text(
                  '« ${_motivation!.quote} »',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF1E293B),
                    height: 1.45,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Badge source (ZenQuotes API ou Conseil Santé)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _motivation!.isFromApi
                            ? Colors.green.shade50
                            : Colors.blueGrey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _motivation!.isFromApi
                                ? Icons.cloud_done_rounded
                                : Icons.health_and_safety_rounded,
                            size: 13,
                            color: _motivation!.isFromApi
                                ? Colors.green.shade700
                                : Colors.blueGrey.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _motivation!.isFromApi ? 'ZenQuotes API' : 'Sport-Santé',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: _motivation!.isFromApi
                                  ? Colors.green.shade800
                                  : Colors.blueGrey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Auteur
                    Flexible(
                      child: Text(
                        '— ${_motivation!.author}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: kTeal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
