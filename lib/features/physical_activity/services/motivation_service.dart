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

  /// Liste de repli de conseils et citations sport-santé / bien-être en français
  static const List<DailyMotivation> fallbackQuotes = [
    DailyMotivation(
      quote: 'La marche est le meilleur remède de l’homme.',
      author: 'Hippocrate',
      category: 'Santé & Longévité',
      isFromApi: false,
    ),
    DailyMotivation(
      quote:
          'Prenez soin de votre corps. C’est le seul endroit où vous êtes obligé de vivre.',
      author: 'Jim Rohn',
      category: 'Bien-être corporel',
      isFromApi: false,
    ),
    DailyMotivation(
      quote:
          'Chaque pas fait du bien à votre cœur. Il n’y a aucun mouvement trop modeste pour votre santé.',
      author: 'Conseil MediTrack',
      category: 'Motivation Sport-Santé',
      isFromApi: false,
    ),
    DailyMotivation(
      quote:
          'L’activité physique libère des endorphines naturelles qui apaisent le stress et élèvent le moral.',
      author: 'Organisation Mondiale de la Santé (OMS)',
      category: 'Santé mentale & Sérénité',
      isFromApi: false,
    ),
    DailyMotivation(
      quote:
          'La persévérance n’est pas une longue course ; c’est plusieurs petits pas accomplis jour après jour.',
      author: 'Walter Elliot',
      category: 'Persévérance',
      isFromApi: false,
    ),
    DailyMotivation(
      quote:
          'Une marche de 20 minutes aujourd’hui vaut infiniment plus que mille intentions parfaites pour demain.',
      author: 'Accompagnement MediTrack',
      category: 'Régularité & Énergie',
      isFromApi: false,
    ),
    DailyMotivation(
      quote:
          'Écoutez votre corps avec bienveillance. Avancez à votre rythme, sans comparaison.',
      author: 'Médecine Préventive',
      category: 'Bienveillance & Écoute',
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
