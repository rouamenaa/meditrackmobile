import 'package:flutter/material.dart';

/// Modèle représentant une recommandation personnalisée d'activité physique.
class ActivityRecommendation {
  final String id;
  final String title;
  final String activityType; // Marche, Course, Vélo, Natation, Autre
  final int durationMinutes;
  final String intensity; // Faible, Modérée, Élevée
  final int frequencyPerWeek;
  final String category; // 'Objectif OMS', 'Reprise en douceur', 'Cardio santé', etc.
  final String reason; // Justification personnalisée selon le profil et l'historique
  final String description; // Conseils pratiques de réalisation
  final int estimatedCalories;
  final String? medicalAdvice; // Mise en garde médicale adaptée
  final String source; // 'Moteur de règles OMS MediTrack' ou API

  const ActivityRecommendation({
    required this.id,
    required this.title,
    required this.activityType,
    required this.durationMinutes,
    required this.intensity,
    required this.frequencyPerWeek,
    required this.category,
    required this.reason,
    required this.description,
    required this.estimatedCalories,
    this.medicalAdvice,
    this.source = 'Moteur de règles OMS MediTrack',
  });

  /// Icône Material adaptée au type d'activité suggéré
  IconData get icon {
    switch (activityType.trim().toLowerCase()) {
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

  /// Couleur d'accentuation liée à l'intensité
  Color get intensityColor {
    switch (intensity.trim().toLowerCase()) {
      case 'faible':
        return const Color(0xFF2E7D32);
      case 'élevée':
      case 'elevee':
        return const Color(0xFFC62828);
      case 'modérée':
      case 'moderee':
      default:
        return const Color(0xFFEF6C00);
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'activityType': activityType,
      'durationMinutes': durationMinutes,
      'intensity': intensity,
      'frequencyPerWeek': frequencyPerWeek,
      'category': category,
      'reason': reason,
      'description': description,
      'estimatedCalories': estimatedCalories,
      'medicalAdvice': medicalAdvice,
      'source': source,
    };
  }

  factory ActivityRecommendation.fromMap(Map<String, dynamic> map) {
    return ActivityRecommendation(
      id: map['id'] as String? ?? 'rec_default',
      title: map['title'] as String? ?? 'Séance d\'activité physique',
      activityType: map['activityType'] as String? ?? 'Marche',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 30,
      intensity: map['intensity'] as String? ?? 'Modérée',
      frequencyPerWeek: (map['frequencyPerWeek'] as num?)?.toInt() ?? 3,
      category: map['category'] as String? ?? 'Santé générale',
      reason: map['reason'] as String? ?? 'Recommandé pour maintenir votre bien-être physique.',
      description: map['description'] as String? ?? 'Pratiquez à votre rythme et hydratez-vous régulièrement.',
      estimatedCalories: (map['estimatedCalories'] as num?)?.toInt() ?? 120,
      medicalAdvice: map['medicalAdvice'] as String?,
      source: map['source'] as String? ?? 'Moteur de règles OMS MediTrack',
    );
  }
}
