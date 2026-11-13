import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_data.dart';

/// Service gérant la géolocalisation et la consommation de l'API Open-Meteo
class WeatherService {
  WeatherService._();
  static final WeatherService instance = WeatherService._();
  factory WeatherService() => instance;

  static const String _cacheKey = 'cached_weather_data';
  static const String _cacheTimeKey = 'cached_weather_timestamp';
  static const Duration _cacheTtl = Duration(minutes: 30);

  // Coordonnées par défaut de repli (ex. Paris / Île-de-France)
  static const double defaultLatitude = 48.8566;
  static const double defaultLongitude = 2.3522;

  WeatherData? _memoryCache;

  /// Récupère la météo courante (avec cache, repli GPS et repli hors-ligne)
  Future<WeatherData> getCurrentWeather({
    bool forceRefresh = false,
    http.Client? client,
  }) async {
    // 1. Vérifier le cache en mémoire ou SharedPreferences si pas de rafraîchissement forcé
    if (!forceRefresh) {
      if (_memoryCache != null) {
        final age = DateTime.now().difference(_memoryCache!.timestamp);
        if (age < _cacheTtl) {
          return _memoryCache!;
        }
      }
      final diskCache = await _readDiskCache();
      if (diskCache != null) {
        _memoryCache = diskCache;
        return diskCache;
      }
    }

    // 2. Déterminer les coordonnées GPS
    final coordinates = await _resolveCoordinates();

    // 3. Appel de l'API Open-Meteo
    final httpClient = client ?? http.Client();
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=${coordinates.latitude}&longitude=${coordinates.longitude}'
        '&current=temperature_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,relative_humidity_2m',
      );

      final response = await httpClient
          .get(url)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final weather = WeatherData.fromOpenMeteoJson(
          json,
          cityName: coordinates.isDefault ? 'Standard Area' : 'Current Location',
        );

        _memoryCache = weather;
        await _saveDiskCache(weather);
        return weather;
      } else {
        debugPrint('[WeatherService] Open-Meteo HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[WeatherService] Network or parsing error: $e');
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }

    // 4. Repli hors-ligne en cas d'échec réseau
    final fallbackCache = await _readDiskCache(ignoreExpiration: true);
    if (fallbackCache != null) {
      return fallbackCache;
    }

    return WeatherData.fallback();
  }

  /// Détermine la position GPS actuelle avec repli gracieux
  Future<_ResolvedPosition> _resolveCoordinates() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const _ResolvedPosition(
          latitude: defaultLatitude,
          longitude: defaultLongitude,
          isDefault: true,
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const _ResolvedPosition(
            latitude: defaultLatitude,
            longitude: defaultLongitude,
            isDefault: true,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const _ResolvedPosition(
          latitude: defaultLatitude,
          longitude: defaultLongitude,
          isDefault: true,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 4),
        ),
      );

      return _ResolvedPosition(
        latitude: position.latitude,
        longitude: position.longitude,
        isDefault: false,
      );
    } catch (e) {
      debugPrint('[WeatherService] Geolocator exception: $e');
      return const _ResolvedPosition(
        latitude: defaultLatitude,
        longitude: defaultLongitude,
        isDefault: true,
      );
    }
  }

  Future<void> _saveDiskCache(WeatherData weather) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(weather.toMap()));
      await prefs.setString(_cacheTimeKey, weather.timestamp.toIso8601String());
    } catch (e) {
      debugPrint('[WeatherService] Error saving cache: $e');
    }
  }

  Future<WeatherData?> _readDiskCache({bool ignoreExpiration = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cacheKey);
      final timeStr = prefs.getString(_cacheTimeKey);

      if (jsonStr == null || timeStr == null) return null;

      final cachedTime = DateTime.parse(timeStr);
      final age = DateTime.now().difference(cachedTime);

      if (!ignoreExpiration && age >= _cacheTtl) {
        return null; // Expiré
      }

      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return WeatherData.fromMap(map);
    } catch (e) {
      debugPrint('[WeatherService] Error reading cache: $e');
      return null;
    }
  }

  /// Réinitialise le cache (utile pour les tests)
  Future<void> clearCache() async {
    _memoryCache = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimeKey);
  }
}

class _ResolvedPosition {
  final double latitude;
  final double longitude;
  final bool isDefault;

  const _ResolvedPosition({
    required this.latitude,
    required this.longitude,
    required this.isDefault,
  });
}
