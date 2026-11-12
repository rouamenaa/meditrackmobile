import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_motivation.dart';

/// Service de consommation de l'API externe ZenQuotes pour les citations
/// et conseils bien-être / motivation sport-santé.
///
/// Fonctionnalités clés :
/// 1. Consommation de l'API externe ZenQuotes (100% gratuite, sans clé API).
/// 2. Mise en cache quotidienne dans SharedPreferences pour éviter de requêter
///    inutilement le réseau et respecter les quotas (limite ZenQuotes 5 req / 30s).
/// 3. Mode rafraîchissement à la demande (forceRefresh).
/// 4. Repli hors-ligne robuste avec citations et conseils sport-santé en français
///    validés pour l'accompagnement médical et psychologique du patient.
class MotivationService {
  MotivationService._();
  static final MotivationService instance = MotivationService._();
  factory MotivationService() => instance;

  static const String _kCacheKey = 'meditrack_daily_motivation_cache';
  static const String _kDateKey = 'meditrack_daily_motivation_date';

  /// URLs de l'API ZenQuotes
  static const String _todayApiUrl = 'https://zenquotes.io/api/today';
  static const String _randomApiUrl = 'https://zenquotes.io/api/random';

  /// Liste de repli de conseils et citations sport-santé / bien-être en anglais
  static const List<DailyMotivation> fallbackQuotes = [
    DailyMotivation(
      quote: 'Walking is man’s best medicine.',
      author: 'Hippocrates',
      category: 'Health & Longevity',
      isFromApi: false,
    ),
    DailyMotivation(
      quote:
          'Take care of your body. It’s the only place you have to live.',
      author: 'Jim Rohn',
      category: 'Physical Well-being',
      isFromApi: false,
    ),
    DailyMotivation(
      quote:
          'Every step does your heart good. No movement is too small for your health.',
      author: 'MediTrack Tip',
      category: 'Health & Fitness Motivation',
      isFromApi: false,
    ),
    DailyMotivation(
      quote:
          'Physical activity releases natural endorphins that relieve stress and boost mood.',
      author: 'World Health Organization (WHO)',
      category: 'Mental Health & Serenity',
      isFromApi: false,
    ),
    DailyMotivation(
      quote:
          'Perseverance is not a long race; it is many short steps taken day after day.',
      author: 'Walter Elliot',
      category: 'Perseverance',
      isFromApi: false,
    ),
    DailyMotivation(
      quote:
          'A 20-minute walk today is worth far more than a thousand perfect intentions for tomorrow.',
      author: 'MediTrack Coaching',
      category: 'Consistency & Energy',
      isFromApi: false,
    ),
    DailyMotivation(
      quote:
          'Listen to your body with kindness. Move at your own pace without comparison.',
      author: 'Preventive Medicine',
      category: 'Mindfulness & Care',
      isFromApi: false,
    ),
  ];

  /// Récupère la citation ou conseil du jour.
  /// - Si déjà en cache pour la date d'aujourd'hui et [forceRefresh] est faux, retourne le cache.
  /// - Sinon, contacte l'API externe ZenQuotes.
  /// - En cas de coupure réseau ou quota dépassé, utilise le catalogue de repli local.
  Future<DailyMotivation> getDailyMotivation({
    bool forceRefresh = false,
    http.Client? client,
  }) async {
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // 1. Vérification du cache local (si pas de forceRefresh)
    if (!forceRefresh) {
      final cached = await _loadFromCache(todayKey);
      if (cached != null) {
        return cached;
      }
    }

    // 2. Appel de l'API externe ZenQuotes
    final httpClient = client ?? http.Client();
    final targetUrl = forceRefresh ? _randomApiUrl : _todayApiUrl;

    try {
      final response = await httpClient
          .get(Uri.parse(targetUrl))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          final first = decoded.first as Map<String, dynamic>;
          final rawQuote = first['q'] as String?;

          // Vérifie qu'il ne s'agit pas du message de limitation de quota de ZenQuotes
          if (rawQuote != null &&
              rawQuote.isNotEmpty &&
              !rawQuote.toLowerCase().contains('too many requests')) {
            final motivation = DailyMotivation.fromZenQuotesJson(first, date: now);
            await _saveToCache(todayKey, motivation);
            return motivation;
          }
        }
      }
    } catch (e) {
      debugPrint('[MOTIVATION SERVICE] Erreur API externe ZenQuotes : $e');
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }

    // 3. Repli hors-ligne fiable et médicalement bienveillant
    final fallback = getLocalFallback(now);
    await _saveToCache(todayKey, fallback);
    return fallback;
  }

  /// Fournit une citation de repli sélectionnée de façon déterministe
  DailyMotivation getLocalFallback([DateTime? date]) {
    final d = date ?? DateTime.now();
    final index = (d.day + d.month) % fallbackQuotes.length;
    final item = fallbackQuotes[index];
    return DailyMotivation(
      quote: item.quote,
      author: item.author,
      category: item.category,
      date: d,
      isFromApi: false,
    );
  }

  /// Chargement depuis SharedPreferences
  Future<DailyMotivation?> _loadFromCache(String todayKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedDate = prefs.getString(_kDateKey);
      final cachedJson = prefs.getString(_kCacheKey);

      if (cachedDate == todayKey && cachedJson != null && cachedJson.isNotEmpty) {
        return DailyMotivation.fromJson(cachedJson);
      }
    } catch (e) {
      debugPrint('[MOTIVATION SERVICE] Erreur lecture cache : $e');
    }
    return null;
  }

  /// Sauvegarde dans SharedPreferences
  Future<void> _saveToCache(String todayKey, DailyMotivation motivation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kDateKey, todayKey);
      await prefs.setString(_kCacheKey, motivation.toJson());
    } catch (e) {
      debugPrint('[MOTIVATION SERVICE] Erreur écriture cache : $e');
    }
  }

  /// Efface le cache (utile pour les tests)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kDateKey);
      await prefs.remove(_kCacheKey);
    } catch (_) {}
  }
}
