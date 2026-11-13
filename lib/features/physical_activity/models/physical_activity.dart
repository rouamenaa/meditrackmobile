import 'package:flutter/material.dart';

class PhysicalActivity {
  final int? id;
  final String? remoteId; // Identifiant distant MongoDB (_id)
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
    this.remoteId,
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
      case 'walking':
        return Icons.directions_walk_rounded;
      case 'course':
      case 'running':
        return Icons.directions_run_rounded;
      case 'vélo':
      case 'velo':
      case 'cycling':
        return Icons.directions_bike_rounded;
      case 'natation':
      case 'swimming':
        return Icons.pool_rounded;
      default:
        return Icons.fitness_center_rounded;
    }
  }

  /// English display label for activity type
  String get typeLabel {
    switch (type.trim().toLowerCase()) {
      case 'marche':
      case 'walking':
        return 'Walking';
      case 'course':
      case 'running':
        return 'Running';
      case 'vélo':
      case 'velo':
      case 'cycling':
        return 'Cycling';
      case 'natation':
      case 'swimming':
        return 'Swimming';
      default:
        return type;
    }
  }

  /// English display label for intensity
  String get intensityLabel {
    switch (intensity.trim().toLowerCase()) {
      case 'faible':
      case 'low':
        return 'Low';
      case 'élevée':
      case 'elevee':
      case 'high':
        return 'High';
      case 'modérée':
      case 'moderee':
      case 'moderate':
        return 'Moderate';
      default:
        return intensity;
    }
  }

  /// Couleur d'accentuation liée à l'intensité de l'effort
  Color get intensityColor {
    switch (intensity.trim().toLowerCase()) {
      case 'faible':
      case 'low':
        return const Color(0xFF2E7D32); // Green
      case 'élevée':
      case 'elevee':
      case 'high':
        return const Color(0xFFC62828); // Red
      case 'modérée':
      case 'moderee':
      case 'moderate':
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
      case 'walking':
        if (normIntensity.contains('faible') || normIntensity.contains('low')) {
          met = 2.8;
        } else if (normIntensity.contains('élev') || normIntensity.contains('elev') || normIntensity.contains('high')) {
          met = 4.8;
        } else {
          met = 3.6;
        }
        break;
      case 'course':
      case 'running':
        if (normIntensity.contains('faible') || normIntensity.contains('low')) {
          met = 7.0;
        } else if (normIntensity.contains('élev') || normIntensity.contains('elev') || normIntensity.contains('high')) {
          met = 11.5;
        } else {
          met = 9.0;
        }
        break;
      case 'vélo':
      case 'velo':
      case 'cycling':
        if (normIntensity.contains('faible') || normIntensity.contains('low')) {
          met = 4.0;
        } else if (normIntensity.contains('élev') || normIntensity.contains('elev') || normIntensity.contains('high')) {
          met = 8.5;
        } else {
          met = 6.0;
        }
        break;
      case 'natation':
      case 'swimming':
        if (normIntensity.contains('faible') || normIntensity.contains('low')) {
          met = 5.5;
        } else if (normIntensity.contains('élev') || normIntensity.contains('elev') || normIntensity.contains('high')) {
          met = 10.0;
        } else {
          met = 7.5;
        }
        break;
      default: // Fitness / Other
        if (normIntensity.contains('faible') || normIntensity.contains('low')) {
          met = 3.0;
        } else if (normIntensity.contains('élev') || normIntensity.contains('elev') || normIntensity.contains('high')) {
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
        'remote_id': remoteId,
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
        remoteId: (map['remote_id'] ?? map['remoteId'])?.toString(),
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

  Map<String, dynamic> toJson() => {
        if (remoteId != null) 'id': remoteId,
        if (id != null) 'localId': id,
        'type': type,
        'durationMinutes': durationMinutes,
        'distanceKm': distanceKm,
        'intensity': intensity,
        'activityDate': activityDate.toIso8601String(),
        'notes': notes,
        'caloriesBurned': caloriesBurned,
      };

  factory PhysicalActivity.fromJson(Map<String, dynamic> json) => PhysicalActivity(
        id: json['localId'] as int?,
        remoteId: (json['id'] ?? json['_id'])?.toString(),
        userId: (json['userId'] ?? json['user'])?.toString(),
        type: json['type'] as String,
        durationMinutes: (json['durationMinutes'] as num).toInt(),
        distanceKm: json['distanceKm'] != null
            ? (json['distanceKm'] as num).toDouble()
            : null,
        intensity: json['intensity'] as String,
        activityDate: DateTime.parse(json['activityDate'] as String),
        notes: json['notes'] as String?,
        caloriesBurned: (json['caloriesBurned'] as num?)?.toInt(),
      );

  PhysicalActivity copyWith({
    int? id,
    String? remoteId,
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
        remoteId: remoteId ?? this.remoteId,
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
