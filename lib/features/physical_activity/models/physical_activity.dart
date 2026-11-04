import 'package:flutter/material.dart';

class PhysicalActivity {
  final int? id;
  final int? userId;
  final String type; // Marche, Course, Vélo, Natation, Autre
  final int durationMinutes;
  final double? distanceKm;
  final String intensity; // Faible, Modérée, Élevée
  final DateTime activityDate;
  final String? notes;
  final int? caloriesBurned; // Facultatif (saisi par l'utilisateur s'il le souhaite)

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
        userId: map['user_id'] as int?,
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
    int? userId,
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
