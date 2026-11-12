import 'dart:convert';

import 'package:http/http.dart' as http;

/// Valeur ajoutée (web service externe) : consulte l'API publique openFDA
/// pour vérifier qu'un nom de médicament est connu et récupérer un résumé.
/// Aucun compte/clé requis. Les erreurs réseau sont silencieuses :
/// la saisie du traitement reste toujours possible hors ligne.
class DrugInfo {
  final String name;
  final String? purpose;
  final String? warnings;
  final bool fromApi;

  const DrugInfo({
    required this.name,
    this.purpose,
    this.warnings,
    this.fromApi = true,
  });
}

class DrugInfoService {
  DrugInfoService._();
  static final DrugInfoService instance = DrugInfoService._();

  static const _base =
      'https://api.fda.gov/drug/label.json';

  /// Recherche un médicament par nom (marque ou générique).
  /// Retourne `null` si introuvable ou en cas d'erreur réseau.
  Future<DrugInfo?> lookup(String query) async {
    final q = query.trim();
    if (q.length < 3) return null;
    try {
      final uri = Uri.parse(_base).replace(queryParameters: {
        'search':
            '(openfda.brand_name:"$q"+openfda.generic_name:"$q")',
        'limit': '1',
      });
      final r = await http.get(uri).timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) return null;
      final body = json.decode(utf8.decode(r.bodyBytes));
      if (body is! Map || body['results'] is! List) return null;
      final results = body['results'] as List;
      if (results.isEmpty) return null;
      final first = Map<String, dynamic>.from(results.first as Map);
      final openfda = first['openfda'] is Map
          ? Map<String, dynamic>.from(first['openfda'] as Map)
          : const <String, dynamic>{};
      final brand = _firstOf(openfda['brand_name']);
      final generic = _firstOf(openfda['generic_name']);
      final purpose = _firstOf(first['purpose']) ?? _firstOf(first['indications_and_usage']);
      final warnings = _firstOf(first['warnings']) ?? _firstOf(first['warnings_and_cautions']);
      return DrugInfo(
        name: brand ?? generic ?? q,
        purpose: _short(purpose),
        warnings: _short(warnings),
      );
    } catch (_) {
      return null; // hors ligne / quota / timeout -> saisie manuelle OK
    }
  }

  String? _firstOf(dynamic v) {
    if (v is List && v.isNotEmpty) return v.first?.toString();
    if (v is String && v.trim().isNotEmpty) return v;
    return null;
  }

  String? _short(String? s) {
    if (s == null) return null;
    final t = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.length <= 180) return t;
    return '${t.substring(0, 177)}...';
  }
}
