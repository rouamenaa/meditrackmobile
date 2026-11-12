import 'package:flutter/material.dart';

class PhysicalActivity {
  final int? id;
  final String? userId; // Identifiant de l'utilisateur (aligné avec MongoDB / Session)
  final String type; // Marche, Course, Vélo, Natation, Autre
  final int durationMinutes;
  final double? distanceKm;
  final String intensity; // Faible, Modérée, Élevée
  final DateTime activityDate;
  final String? notes;
  final int? caloriesBurned; // Calculé automatiquement ou saisi par l'utilisateur

  PhysicalActivity({
    this.id,
    this.userId,
    required this.type,
    required this.durationMinutes,
    this.distanceKm,
    required this.intensity,
    required this.activityDate,
    this.notes,
    this.caloriesBurned,
  });

  /// Icône Material adaptée au type d'activité
  IconData get icon {
    switch (type.trim().toLowerCase()) {
      case 'marche':
        return Icons.directions_walk_rounded;
      case 'course':
        return Icons.directions_run_rounded;
      case 'vélo':
      case 'velo':
        return Icons.directions_bike_rounded;
      case 'natation':
        return Icons.pool_rounded;
      default:
        return Icons.fitness_center_rounded;
    }
  }

  /// Couleur d'accentuation liée à l'intensité de l'effort
  Color get intensityColor {
    switch (intensity.trim().toLowerCase()) {
      case 'faible':
        return const Color(0xFF2E7D32); // Vert
      case 'élevée':
      case 'elevee':
        return const Color(0xFFC62828); // Rouge
      case 'modérée':
      case 'moderee':
      default:
        return const Color(0xFFEF6C00); // Orange
    }
  }

  /// Allure moyenne (ex: 5'30"/km) si la distance est renseignée et positive
  String? get paceLabel {
    if (distanceKm == null || distanceKm! <= 0 || durationMinutes <= 0) {
      return null;
    }
    final paceDecimal = durationMinutes / distanceKm!;
    final minutes = paceDecimal.floor();
    final seconds = ((paceDecimal - minutes) * 60).round();
    return "$minutes'${seconds.toString().padLeft(2, '0')}\"/km";
  }

  /// Vitesse moyenne en km/h si la distance est renseignée et positive
  double? get speedKmh {
    if (distanceKm == null || distanceKm! <= 0 || durationMinutes <= 0) {
      return null;
    }
    return distanceKm! / (durationMinutes / 60.0);
  }

  /// Estimation automatique des calories brûlées via le standard médical MET (Metabolic Equivalent of Task)
  /// Formule : Calories = MET * poids(kg) * (durée en heures)
  static int calculateEstimatedCalories({
    required String type,
    required int durationMinutes,
    required String intensity,
    double weightKg = 70.0,
  }) {
    if (durationMinutes <= 0) return 0;

    double met;
    final normType = type.trim().toLowerCase();
    final normIntensity = intensity.trim().toLowerCase();

    switch (normType) {
      case 'marche':
        if (normIntensity.contains('faible')) {
          met = 2.8;
        } else if (normIntensity.contains('élev') || normIntensity.contains('elev')) {
          met = 4.8;
        } else {
          met = 3.6;
        }
        break;
      case 'course':
        if (normIntensity.contains('faible')) {
          met = 7.0;
        } else if (normIntensity.contains('élev') || normIntensity.contains('elev')) {
          met = 11.5;
        } else {
          met = 9.0;
        }
        break;
      case 'vélo':
      case 'velo':
        if (normIntensity.contains('faible')) {
          met = 4.0;
        } else if (normIntensity.contains('élev') || normIntensity.contains('elev')) {
          met = 8.5;
        } else {
          met = 6.0;
        }
        break;
      case 'natation':
        if (normIntensity.contains('faible')) {
          met = 5.5;
        } else if (normIntensity.contains('élev') || normIntensity.contains('elev')) {
          met = 10.0;
        } else {
          met = 7.5;
        }
        break;
      default: // Fitness / Autre
        if (normIntensity.contains('faible')) {
          met = 3.0;
        } else if (normIntensity.contains('élev') || normIntensity.contains('elev')) {
          met = 7.5;
        } else {
          met = 5.0;
        }
        break;
    }

    final hours = durationMinutes / 60.0;
    return (met * weightKg * hours).round();
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'type': type,
        'duration_minutes': durationMinutes,
        'distance_km': distanceKm,
        'intensity': intensity,
        'activity_date': activityDate.toIso8601String(),
        'notes': notes,
        'calories_burned': caloriesBurned,
      };

  factory PhysicalActivity.fromMap(Map<String, dynamic> map) => PhysicalActivity(
        id: map['id'] as int?,
        userId: map['user_id']?.toString(),
        type: map['type'] as String,
        durationMinutes: map['duration_minutes'] as int,
        distanceKm: map['distance_km'] != null
            ? (map['distance_km'] as num).toDouble()
            : null,
        intensity: map['intensity'] as String,
        activityDate: DateTime.parse(map['activity_date'] as String),
        notes: map['notes'] as String?,
        caloriesBurned: map['calories_burned'] as int?,
      );

  PhysicalActivity copyWith({
    int? id,
    String? userId,
    String? type,
    int? durationMinutes,
    double? distanceKm,
    String? intensity,
    DateTime? activityDate,
    String? notes,
    int? caloriesBurned,
  }) =>
      PhysicalActivity(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        type: type ?? this.type,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        distanceKm: distanceKm ?? this.distanceKm,
        intensity: intensity ?? this.intensity,
        activityDate: activityDate ?? this.activityDate,
        notes: notes ?? this.notes,
        caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      );
}
