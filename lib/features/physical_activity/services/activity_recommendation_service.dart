import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../auth/models/user.dart';
import '../models/activity_recommendation.dart';
import '../models/physical_activity.dart';
import 'activity_service.dart';

/// Moteur de recommandations personnalisées d'activité physique pour MediTrack.
///
/// Principes :
/// 1. Basé sur les données réelles du patient issues de `User` (âge, sexe, condition médicale).
/// 2. Aucune donnée manquante n'est inventée (ex. poids/taille non présents dans User).
/// 3. Analyse de l'historique complet : types favoris, fréquence, durée cumulée et intensité.
/// 4. Alignement strict avec les recommandations OMS (150 min/semaine).
/// 5. Sécurité médicale : les patients avec une condition médicale reçoivent une intensité adaptée
///    et un rappel formel de validation par leur médecin traitant (aucune prescription médicale automatique).
/// 6. Intégration d'un client API externe optionnel pour enrichir les conseils santé avec repli hors-ligne.
class ActivityRecommendationService {
  ActivityRecommendationService._();
  static final ActivityRecommendationService instance =
      ActivityRecommendationService._();
  factory ActivityRecommendationService() => instance;

  /// Génère la liste des recommandations personnalisées
  List<ActivityRecommendation> generateRecommendations({
    User? user,
    required List<PhysicalActivity> history,
    required ActivityWeeklySummary summary,
  }) {
    final age = user?.age;
    final medicalCondition = user?.conditionMedicale;
    final hasCondition =
        medicalCondition != null && medicalCondition.trim().isNotEmpty;
    final isSenior = age != null && age >= 65;
    final weeklyMinutes = summary.totalMinutes;

    // Avertissement médical déontologique personnalisé
    final String? medicalNotice = hasCondition
        ? 'Prior medical consultation: Given your reported medical condition ($medicalCondition), please consult your attending physician before starting this program.'
        : (isSenior
            ? 'Senior tip: Warm up for 5 to 10 minutes and prioritize gentle, progressive movements.'
            : null);

    // Analyse de l'historique des activités
    final typeCounts = <String, int>{};
    for (final act in history) {
      final t = act.typeLabel;
      typeCounts[t] = (typeCounts[t] ?? 0) + 1;
    }

    // Sport le plus pratiqué par le patient
    String preferredType = 'Walking';
    int maxCount = 0;
    typeCounts.forEach((key, count) {
      if (count > maxCount) {
        maxCount = count;
        preferredType = key;
      }
    });

    final recommendations = <ActivityRecommendation>[];

    // -------------------------------------------------------------------------
    // 1. RECOMMANDATION PRINCIPALE (Ajustée selon la progression OMS)
    // -------------------------------------------------------------------------
    if (weeklyMinutes < 60) {
      // Profil débutant ou reprise après interruption
      const duration = 25;
      const intensity = 'Low';
      recommendations.add(
        ActivityRecommendation(
          id: 'rec_starter_walk',
          title: 'Active fitness walking',
          activityType: 'Walking',
          durationMinutes: duration,
          intensity: intensity,
          frequencyPerWeek: 3,
          category: 'Gentle Restart',
          reason: weeklyMinutes == 0
              ? 'No workouts logged this week. A 25-minute walk is the perfect starting point to re-energize your body.'
              : 'You have logged $weeklyMinutes min this week. This accessible session lets you steadily build your activity volume.',
          description:
              'Walk at a steady, brisk pace, breathe deeply, and wear comfortable footwear. Stay hydrated before and after.',
          estimatedCalories: PhysicalActivity.calculateEstimatedCalories(
            type: 'Walking',
            durationMinutes: duration,
            intensity: intensity,
          ),
          medicalAdvice: medicalNotice,
        ),
      );
    } else if (weeklyMinutes < 150) {
      // En bonne voie vers l'objectif OMS de 150 min
      final remaining = 150 - weeklyMinutes;
      final suggestedDuration = remaining.clamp(30, 45);
      final intensity = hasCondition ? 'Low' : 'Moderate';
      final activity = preferredType == 'Running' && !hasCondition && !isSenior
          ? 'Running'
          : (preferredType == 'Cycling' ? 'Cycling' : 'Walking');

      recommendations.add(
        ActivityRecommendation(
          id: 'rec_who_progress',
          title: 'WHO Goal Session (150 min/week)',
          activityType: activity,
          durationMinutes: suggestedDuration,
          intensity: intensity,
          frequencyPerWeek: 3,
          category: 'WHO Progression',
          reason:
              'You have already completed $weeklyMinutes min of activity this week! Just $remaining min left to reach the WHO recommended 150 minutes.',
          description:
              'Maintain a dynamic yet comfortable pace where you can still talk without gasping.',
          estimatedCalories: PhysicalActivity.calculateEstimatedCalories(
            type: activity,
            durationMinutes: suggestedDuration,
            intensity: intensity,
          ),
          medicalAdvice: medicalNotice,
        ),
      );
    } else {
      // Objectif OMS déjà atteint !
      const duration = 40;
      final intensity = (hasCondition || isSenior) ? 'Moderate' : 'High';
      recommendations.add(
        ActivityRecommendation(
          id: 'rec_who_achieved',
          title: 'Endurance maintenance session',
          activityType: preferredType,
          durationMinutes: duration,
          intensity: intensity,
          frequencyPerWeek: 4,
          category: 'WHO Goal Achieved 🎯',
          reason:
              'Congratulations! You reached your goal with $weeklyMinutes min of activity this week. This session sustains your cardiovascular fitness.',
          description:
              'Maintenance workout at your preferred pace. Finish with 5 minutes of cool-down and stretching.',
          estimatedCalories: PhysicalActivity.calculateEstimatedCalories(
            type: preferredType,
            durationMinutes: duration,
            intensity: intensity,
          ),
          medicalAdvice: medicalNotice,
        ),
      );
    }

    // -------------------------------------------------------------------------
    // 2. RECOMMANDATION ARTICULAIRE ET CROISÉE (Cyclisme ou Natation)
    // -------------------------------------------------------------------------
    final crossType = preferredType == 'Cycling' ? 'Swimming' : 'Cycling';
    const crossDuration = 35;
    const crossIntensity = 'Moderate';
    recommendations.add(
      ActivityRecommendation(
        id: 'rec_cross_training',
        title: crossType == 'Cycling'
            ? 'Gentle cycling to protect joints'
            : 'Fluid swimming and back stretch',
        activityType: crossType,
        durationMinutes: crossDuration,
        intensity: hasCondition ? 'Low' : crossIntensity,
        frequencyPerWeek: 2,
        category: 'Joint Protection',
        reason:
            'Practicing a low-impact activity like $crossType relieves joint strain while providing excellent complementary cardiovascular benefits.',
        description: crossType == 'Cycling'
            ? 'Pedal at a smooth cadence (60-70 rpm) on flat terrain or a stationary bike.'
            : 'Swim comfortably (breaststroke or freestyle), fully extending each stroke.',
        estimatedCalories: PhysicalActivity.calculateEstimatedCalories(
          type: crossType,
          durationMinutes: crossDuration,
          intensity: hasCondition ? 'Low' : crossIntensity,
        ),
        medicalAdvice: medicalNotice,
      ),
    );

    // -------------------------------------------------------------------------
    // 3. RECOMMANDATION CARDIO FRACTIONNÉ OU MARCHE DYNAMIQUE
    // -------------------------------------------------------------------------
    if (!hasCondition && !isSenior && (weeklyMinutes >= 60 || preferredType == 'Running')) {
      const runDuration = 30;
      recommendations.add(
        ActivityRecommendation(
          id: 'rec_interval_cardio',
          title: 'Aerobic base & Light intervals',
          activityType: 'Running',
          durationMinutes: runDuration,
          intensity: 'Moderate',
          frequencyPerWeek: 2,
          category: 'Cardio Strengthening',
          reason:
              'Your history shows consistent dedication. Alternating moderate-pace running stimulates your cardiorespiratory system.',
          description:
              'Warm up for 10 min walking, then run at a conversational pace. Finish with a brisk walk.',
          estimatedCalories: PhysicalActivity.calculateEstimatedCalories(
            type: 'Running',
            durationMinutes: runDuration,
            intensity: 'Moderate',
          ),
          medicalAdvice: medicalNotice,
        ),
      );
    } else {
      const walkDuration = 30;
      recommendations.add(
        ActivityRecommendation(
          id: 'rec_interval_walk',
          title: 'Paced walking session',
          activityType: 'Walking',
          durationMinutes: walkDuration,
          intensity: 'Moderate',
          frequencyPerWeek: 3,
          category: 'Daily Vitality',
          reason:
              'Ideal for stimulating circulation without excess cardiac strain. Tailored to your health profile.',
          description:
              'Alternate 4 minutes of normal walking and 1 minute of brisk walking, repeated 6 times.',
          estimatedCalories: PhysicalActivity.calculateEstimatedCalories(
            type: 'Walking',
            durationMinutes: walkDuration,
            intensity: 'Moderate',
          ),
          medicalAdvice: medicalNotice,
        ),
      );
    }

    // -------------------------------------------------------------------------
    // 4. RECOMMANDATION POSTURE & TONUS MUSCULAIRE (Gym douce / Renforcement)
    // -------------------------------------------------------------------------
    const tonusDuration = 20;
    recommendations.add(
      ActivityRecommendation(
        id: 'rec_muscle_tone',
        title: 'Gentle gymnastics, posture & balance',
        activityType: 'Other',
        durationMinutes: tonusDuration,
        intensity: 'Low',
        frequencyPerWeek: 2,
        category: 'Balance & Mobility',
        reason:
            'Maintaining muscle tone and balance prevents injuries and amplifies the benefits of cardio exercise.',
        description:
            'Gentle stretching, core stability, and deep breathing. Can be done on an exercise mat or seated on a chair.',
        estimatedCalories: PhysicalActivity.calculateEstimatedCalories(
          type: 'Other',
          durationMinutes: tonusDuration,
          intensity: 'Low',
        ),
        medicalAdvice: medicalNotice,
      ),
    );

    return recommendations;
  }

  /// Récupération optionnelle de conseils complémentaires via une API externe
  /// (avec repli hors-ligne immédiat et sécurisé)
  Future<List<String>> fetchExternalHealthTips({String? category}) async {
    try {
      final url = Uri.parse('https://zenquotes.io/api/random');
      final response = await http.get(url).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          final first = decoded.first as Map<String, dynamic>;
          final quote = first['q'] as String?;
          if (quote != null && quote.isNotEmpty) {
            return [
              'Motivational tip: "$quote"',
              'WHO Recommendation: Practice at least 150 minutes of moderate-intensity activity per week.',
            ];
          }
        }
      }
    } catch (e) {
      debugPrint('[ACTIVITY RECOMMENDATIONS] Repli hors-ligne pour l\'API : $e');
    }

    // Repli de conseils médicaux fiables et vérifiés
    return const [
      'WHO Recommendation: Aim for at least 150 minutes of moderate-intensity physical activity per week to reduce cardiovascular risk by 30%.',
      'Hydration: Drink a few sips of water before, during, and after each session.',
      'Consistency: Three 20-minute sessions are better than one single 60-minute session on the weekend.',
      'Safety: If you experience unusual pain, dizziness, or abnormal shortness of breath, stop exercising and consult your doctor.',
    ];
  }
}
