/// ============================================================
/// Service – Recherche de médicaments par nom via RxNorm (NIH)
/// API gratuite, sans clé, base de données pharmaceutique US
/// Documentation : https://lhncbc.nlm.nih.gov/RxNav/APIs/
///
/// Valeur Ajoutée : consommation de web service externe
/// ============================================================
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Un médicament retourné par l'API RxNorm
class DrugSearchResult {
  final String rxcui;       // identifiant RxNorm
  final String name;        // nom générique ex: "ibuprofen"
  final String? dosage;     // ex: "200 MG"
  final String? form;       // ex: "Oral Tablet"
  final String displayName; // nom complet pour l'affichage

  const DrugSearchResult({
    required this.rxcui,
    required this.name,
    required this.displayName,
    this.dosage,
    this.form,
  });
}

class DrugSearchException implements Exception {
  final String message;
  DrugSearchException(this.message);
  @override
  String toString() => message;
}

class DrugSearchService {
  DrugSearchService._();
  static final DrugSearchService instance = DrugSearchService._();
  factory DrugSearchService() => instance;

  static const _base = 'https://rxnav.nlm.nih.gov/REST';
  static const _timeout = Duration(seconds: 10);

  /// Recherche approximative par nom — retourne jusqu'à [limit] résultats.
  Future<List<DrugSearchResult>> search(String query, {int limit = 8}) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final http.Response resp;
    try {
      resp = await http
          .get(Uri.parse(
              '$_base/drugs.json?name=${Uri.encodeComponent(q)}'))
          .timeout(_timeout);
    } on SocketException {
      throw DrugSearchException('No internet connection.');
    } on TimeoutException {
      throw DrugSearchException('Server is not responding.');
    } on Exception catch (e) {
      throw DrugSearchException('Network error: $e');
    }

    if (resp.statusCode != 200) {
      throw DrugSearchException('Server error (${resp.statusCode}).');
    }

    final json = jsonDecode(resp.body);
    final drugGroup = json['drugGroup'] as Map<String, dynamic>?;
    final conceptGroups = drugGroup?['conceptGroup'] as List<dynamic>?;
    if (conceptGroups == null) return [];

    final results = <DrugSearchResult>[];

    for (final group in conceptGroups) {
      final props = group['conceptProperties'] as List<dynamic>?;
      if (props == null) continue;
      for (final p in props) {
        if (results.length >= limit) break;
        final fullName = p['name'] as String? ?? '';
        final rxcui = p['rxcui'] as String? ?? '';
        if (fullName.isEmpty || rxcui.isEmpty) continue;

        // Extraire dosage : "200 MG", "20 MG/ML", etc.
        final doseMatch =
            RegExp(r'(\d+(?:\.\d+)?\s*(?:MG/ML|MG|MCG|ML|%))')
                .firstMatch(fullName);
        final dosage = doseMatch?.group(0);

        // Extraire forme pharmaceutique
        final formMatch = RegExp(
          r'(Oral Tablet|Oral Capsule|Oral Suspension|Oral Solution|'
          r'Injection|Topical Gel|Topical Cream|Chewable Tablet|'
          r'Extended Release|Patch|Drops)',
          caseSensitive: false,
        ).firstMatch(fullName);
        final form = formMatch?.group(0);

        // Nom propre (molécule seule, sans chiffres)
        final cleanName = fullName
            .replaceAll(RegExp(r'\d+(?:\.\d+)?\s*(?:MG/ML|MG|MCG|ML|%).*'), '')
            .replaceAll(RegExp(r'\[.*?\]'), '')
            .trim();

        results.add(DrugSearchResult(
          rxcui: rxcui,
          name: cleanName.isNotEmpty ? cleanName : fullName,
          displayName: fullName,
          dosage: dosage,
          form: form,
        ));
      }
      if (results.length >= limit) break;
    }

    return results;
  }
}
