import 'package:flutter/material.dart';

/// Modèle représentant les conditions météorologiques actuelles pour l'activité physique
class WeatherData {
  final double temperature; // °C
  final double apparentTemperature; // °C ressentie
  final int weatherCode; // Code WMO Open-Meteo
  final double precipitation; // mm
  final double windSpeed; // km/h
  final int humidity; // %
  final DateTime timestamp;
  final String? cityName;

  const WeatherData({
    required this.temperature,
    required this.apparentTemperature,
    required this.weatherCode,
    required this.precipitation,
    required this.windSpeed,
    required this.humidity,
    required this.timestamp,
    this.cityName,
  });

  /// Description textuelle anglaise standard basée sur les codes WMO Open-Meteo
  String get weatherDescription {
    switch (weatherCode) {
      case 0:
        return 'Clear Sky';
      case 1:
        return 'Mainly Clear';
      case 2:
        return 'Partly Cloudy';
      case 3:
        return 'Overcast';
      case 45:
      case 48:
        return 'Foggy';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 56:
      case 57:
        return 'Freezing Drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rainy';
      case 66:
      case 67:
        return 'Freezing Rain';
      case 71:
      case 73:
      case 75:
      case 77:
        return 'Snowy';
      case 80:
      case 81:
      case 82:
        return 'Rain Showers';
      case 85:
      case 86:
        return 'Snow Showers';
      case 95:
      case 96:
      case 99:
        return 'Thunderstorm';
      default:
        return 'Variable Weather';
    }
  }

  /// Icône Material adaptée aux conditions
  IconData get weatherIcon {
    switch (weatherCode) {
      case 0:
        return Icons.wb_sunny_rounded;
      case 1:
      case 2:
        return Icons.wb_cloudy_rounded;
      case 3:
        return Icons.cloud_rounded;
      case 45:
      case 48:
        return Icons.foggy;
      case 51:
      case 53:
      case 55:
      case 61:
      case 63:
      case 65:
      case 80:
      case 81:
      case 82:
        return Icons.water_drop_rounded;
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return Icons.ac_unit_rounded;
      case 95:
      case 96:
      case 99:
        return Icons.thunderstorm_rounded;
      default:
        return Icons.thermostat_rounded;
    }
  }

  /// Couleur d'accentuation liée à la météo
  Color get weatherColor {
    if (isRainy || isStormy) return const Color(0xFF1E88E5);
    if (isSnowy) return const Color(0xFF00ACC1);
    if (isHot) return const Color(0xFFE53935);
    if (isFreezing) return const Color(0xFF3949AB);
    if (weatherCode == 0 || weatherCode == 1) return const Color(0xFFF57C00);
    return const Color(0xFF546E7A);
  }

  /// Conditions de pluie / averses
  bool get isRainy =>
      (weatherCode >= 51 && weatherCode <= 67) ||
      (weatherCode >= 80 && weatherCode <= 82) ||
      precipitation > 0.5;

  /// Conditions orageuses
  bool get isStormy => weatherCode >= 95;

  /// Conditions de neige / verglas
  bool get isSnowy =>
      (weatherCode >= 71 && weatherCode <= 77) ||
      (weatherCode >= 85 && weatherCode <= 86);

  /// Forte chaleur
  bool get isHot => temperature >= 28 || apparentTemperature >= 30;

  /// Grand froid
  bool get isFreezing => temperature <= 5;

  /// Vent soutenu
  bool get isWindy => windSpeed >= 35;

  /// Les conditions sont-elles idéales pour le sport en plein air ?
  bool get isOutdoorFriendly =>
      !isRainy &&
      !isStormy &&
      !isSnowy &&
      temperature >= 5 &&
      temperature <= 29 &&
      windSpeed < 40;

  /// Conseil médical & sportif d'adaptation aux conditions du moment
  String get weatherSportAdvice {
    if (isStormy) {
      return 'Thunderstorm risk: Avoid outdoor exercise. Prioritize indoor fitness, yoga, or rest.';
    }
    if (isRainy) {
      return 'Rainy weather: Wet ground increases slip hazards. Favor indoor workouts or swimming.';
    }
    if (isSnowy) {
      return 'Snow and cold: Surfaces may be slippery. Choose indoor gym or gentle indoor cardio.';
    }
    if (isHot) {
      return 'High temperature (${temperature.round()}°C): Train early morning or indoors. Drink plenty of water.';
    }
    if (isFreezing) {
      return 'Chilly weather (${temperature.round()}°C): Extend your warm-up by 10 minutes and wear thermal layers.';
    }
    if (isWindy) {
      return 'Strong winds (${windSpeed.round()} km/h): Avoid road cycling; prefer sheltered walking or indoor workout.';
    }
    return 'Optimal weather (${temperature.round()}°C): Ideal conditions for outdoor walking, running, or cycling!';
  }

  /// Recommandation sportive principale adaptée aux conditions météo
  String get primarySportRecommendation {
    if (isStormy) return 'Indoor Core & Yoga';
    if (isRainy) return 'Indoor Cardio or Swimming';
    if (isSnowy) return 'Indoor Strength & Gym';
    if (isHot) return 'Early Morning Walk or Swimming';
    if (isFreezing) return 'Indoor Fitness or Brisk Walk';
    if (isWindy) return 'Sheltered Walking or Treadmill';
    return 'Outdoor Walking, Running or Cycling';
  }

  /// Types d'activités adaptées sous forme de tags
  List<String> get recommendedSports {
    if (isStormy) {
      return ['Yoga', 'Stretching', 'Indoor Fitness'];
    }
    if (isRainy) {
      return ['Swimming', 'Indoor Cardio', 'Yoga', 'Pilates'];
    }
    if (isSnowy) {
      return ['Indoor Gym', 'Yoga', 'Indoor Cycling'];
    }
    if (isHot) {
      return ['Swimming', 'Walking', 'Yoga'];
    }
    if (isFreezing) {
      return ['Walking', 'Indoor Gym', 'Yoga'];
    }
    if (isWindy) {
      return ['Walking', 'Running', 'Yoga', 'Swimming'];
    }
    // Idéal plein air
    return ['Walking', 'Running', 'Cycling', 'Yoga'];
  }

  Map<String, dynamic> toMap() => {
        'temperature': temperature,
        'apparent_temperature': apparentTemperature,
        'weather_code': weatherCode,
        'precipitation': precipitation,
        'wind_speed': windSpeed,
        'humidity': humidity,
        'timestamp': timestamp.toIso8601String(),
        'city_name': cityName,
      };

  factory WeatherData.fromMap(Map<String, dynamic> map) => WeatherData(
        temperature: (map['temperature'] as num).toDouble(),
        apparentTemperature: (map['apparent_temperature'] as num).toDouble(),
        weatherCode: (map['weather_code'] as num).toInt(),
        precipitation: (map['precipitation'] as num).toDouble(),
        windSpeed: (map['wind_speed'] as num).toDouble(),
        humidity: (map['humidity'] as num).toInt(),
        timestamp: DateTime.parse(map['timestamp'] as String),
        cityName: map['city_name'] as String?,
      );

  factory WeatherData.fromOpenMeteoJson(Map<String, dynamic> json, {String? cityName}) {
    final current = json['current'] as Map<String, dynamic>? ?? {};
    return WeatherData(
      temperature: (current['temperature_2m'] as num?)?.toDouble() ?? 20.0,
      apparentTemperature:
          (current['apparent_temperature'] as num?)?.toDouble() ?? 20.0,
      weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
      precipitation: (current['precipitation'] as num?)?.toDouble() ?? 0.0,
      windSpeed: (current['wind_speed_10m'] as num?)?.toDouble() ?? 10.0,
      humidity: (current['relative_humidity_2m'] as num?)?.toInt() ?? 50,
      timestamp: DateTime.now(),
      cityName: cityName,
    );
  }

  /// Repli fiable hors-ligne par défaut
  static WeatherData fallback() => WeatherData(
        temperature: 20.0,
        apparentTemperature: 20.0,
        weatherCode: 1, // Mainly clear
        precipitation: 0.0,
        windSpeed: 10.0,
        humidity: 50,
        timestamp: DateTime.now(),
        cityName: 'Local Area',
      );
}
