import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class RouteInfo {
  final double distanceKm;
  final int durationMinutes;

  const RouteInfo({
    required this.distanceKm,
    required this.durationMinutes,
  });

  String get formattedDistance {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String get formattedDuration {
    if (durationMinutes < 60) {
      return '$durationMinutes min';
    }
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    return '${hours}h ${mins > 0 ? '$mins min' : ''}'.trim();
  }
}

class RoutingService {
  RoutingService._();
  static final RoutingService instance = RoutingService._();

  /// Consomme l'API REST publique d'OSRM (Open Source Routing Machine).
  /// Calcule la distance (en mètres) et la durée (en secondes) en voiture.
  Future<RouteInfo?> getDrivingRoute({
    required double startLat,
    required double startLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      // OSRM attend le format : longitude,latitude;longitude,latitude
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$startLng,$startLat;$destLng,$destLat?overview=false',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['code'] == 'Ok' && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final distanceMeters = (route['distance'] as num).toDouble();
          final durationSeconds = (route['duration'] as num).toDouble();

          return RouteInfo(
            distanceKm: distanceMeters / 1000.0,
            durationMinutes: (durationSeconds / 60.0).round(),
          );
        }
      }
    } catch (_) {
      // En cas de problème réseau ou timeout, on retourne null
    }
    return null;
  }

  /// Ouvre l'application de cartographie du téléphone (Google Maps / Apple Maps ou navigateur)
  Future<bool> openMapNavigation({
    required double destLat,
    required double destLng,
    String? destinationLabel,
  }) async {
    final label = Uri.encodeComponent(destinationLabel ?? 'Appointment location');
    
    // 1. Essai avec le protocole direct Google Maps navigation
    final googleMapsAppUrl = Uri.parse('google.navigation:q=$destLat,$destLng');
    try {
      if (await canLaunchUrl(googleMapsAppUrl)) {
        return await launchUrl(googleMapsAppUrl);
      }
    } catch (_) {}

    // 2. Essai avec le schéma universel geo:
    final geoUrl = Uri.parse('geo:$destLat,$destLng?q=$destLat,$destLng($label)');
    try {
      if (await canLaunchUrl(geoUrl)) {
        return await launchUrl(geoUrl);
      }
    } catch (_) {}

    // 3. Fallback garanti : ouverture dans le navigateur web ou l'app Maps
    final webMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$destLat,$destLng',
    );
    try {
      return await launchUrl(webMapsUrl, mode: LaunchMode.externalApplication);
    } catch (_) {
      return await launchUrl(webMapsUrl, mode: LaunchMode.platformDefault);
    }
  }
}

