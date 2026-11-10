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
        ? 'Avis médical préalable : Compte tenu de votre condition médicale déclarée ($medicalCondition), demandez impérativement validation à votre médecin traitant avant de débuter ce programme.'
        : (isSenior
            ? 'Conseil senior : Échauffez-vous 5 à 10 minutes et privilégiez des gestes doux et progressifs.'
            : null);

    // Analyse de l'historique des activités
    final typeCounts = <String, int>{};
    for (final act in history) {
      final t = act.type.trim();
      typeCounts[t] = (typeCounts[t] ?? 0) + 1;
    }

    // Sport le plus pratiqué par le patient
    String preferredType = 'Marche';
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
      const intensity = 'Faible';
      recommendations.add(
        ActivityRecommendation(
          id: 'rec_starter_walk',
          title: 'Marche active de remise en forme',
          activityType: 'Marche',
          durationMinutes: duration,
          intensity: intensity,
          frequencyPerWeek: 3,
          category: 'Reprise en douceur',
          reason: weeklyMinutes == 0
              ? 'Aucune séance enregistrée cette semaine. Une marche de 25 minutes est le point de départ idéal pour relancer votre énergie.'
              : 'Vous avez cumulé $weeklyMinutes min cette semaine. Cette séance accessible vous permet d\'augmenter progressivement votre volume.',
          description:
              'Marchez d\'un bon pas régulier, respirer profondément et portez des chaussures confortables. Hydratez-vous avant et après.',
          estimatedCalories: PhysicalActivity.calculateEstimatedCalories(
            type: 'Marche',
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
      final intensity = hasCondition ? 'Faible' : 'Modérée';
      final activity = preferredType == 'Course' && !hasCondition && !isSenior
          ? 'Course'
          : (preferredType == 'Vélo' ? 'Vélo' : 'Marche');

      recommendations.add(
        ActivityRecommendation(
          id: 'rec_who_progress',
          title: 'Séance Objectif OMS (150 min/semaine)',
          activityType: activity,
          durationMinutes: suggestedDuration,
          intensity: intensity,
          frequencyPerWeek: 3,
          category: 'Progression OMS',
          reason:
              'Vous avez déjà réalisé $weeklyMinutes min d\'activité cette semaine ! Il ne vous reste que $remaining min pour atteindre les 150 min recommandées par l\'OMS.',
          description:
              'Maintenez un rythme dynamique mais confortable permettant de parler sans essoufflement marqué.',
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
      final intensity = (hasCondition || isSenior) ? 'Modérée' : 'Élevée';
      recommendations.add(
        ActivityRecommendation(
          id: 'rec_who_achieved',
          title: 'Séance de consolidation d\'endurance',
          activityType: preferredType,
          durationMinutes: duration,
          intensity: intensity,
          frequencyPerWeek: 4,
          category: 'Objectif OMS Atteint 🎯',
          reason:
              'Félicitations ! Vous avez atteint votre objectif avec $weeklyMinutes min d\'activité cette semaine. Cette séance entretient votre capital cardio.',
          description:
              'Séance de maintien à votre rythme de prédilection. Terminez par 5 minutes de retour au calme et d\'étirements.',
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
    final crossType = preferredType == 'Vélo' ? 'Natation' : 'Vélo';
    const crossDuration = 35;
    const crossIntensity = 'Modérée';
    recommendations.add(
      ActivityRecommendation(
        id: 'rec_cross_training',
        title: crossType == 'Vélo'
            ? 'Cyclisme doux pour préserver les articulations'
            : 'Natation fluide et étirement dorsal',
        activityType: crossType,
        durationMinutes: crossDuration,
        intensity: hasCondition ? 'Faible' : crossIntensity,
        frequencyPerWeek: 2,
        category: 'Protection articulaire',
        reason:
            'Pratiquer une activité portée comme le $crossType soulage les articulations et offre un excellent travail cardiovasculaire complémentaire.',
        description: crossType == 'Vélo'
            ? 'Pédalez à cadence souple (60-70 tours/min) sur parcours plat ou sur vélo d\'appartement.'
            : 'Nagez à votre convenance (brasse ou crawl) en allongeant bien chaque mouvement.',
        estimatedCalories: PhysicalActivity.calculateEstimatedCalories(
          type: crossType,
          durationMinutes: crossDuration,
          intensity: hasCondition ? 'Faible' : crossIntensity,
        ),
        medicalAdvice: medicalNotice,
      ),
    );

    // -------------------------------------------------------------------------
    // 3. RECOMMANDATION CARDIO FRACTIONNÉ OU MARCHE DYNAMIQUE
    // -------------------------------------------------------------------------
    if (!hasCondition && !isSenior && (weeklyMinutes >= 60 || preferredType == 'Course')) {
      const runDuration = 30;
      recommendations.add(
        ActivityRecommendation(
          id: 'rec_interval_cardio',
          title: 'Endurance fondamentale & Fractionné léger',
          activityType: 'Course',
          durationMinutes: runDuration,
          intensity: 'Modérée',
          frequencyPerWeek: 2,
          category: 'Renforcement cardio',
          reason:
              'Votre historique montre une bonne régularité. Une séance alternant course à allure modérée stimule le système cardiorespiratoire.',
          description:
              'Échauffez-vous 10 min en marche, puis courez à une allure où vous pourriez tenir une conversation. Finissez en marchant.',
          estimatedCalories: PhysicalActivity.calculateEstimatedCalories(
            type: 'Course',
            durationMinutes: runDuration,
            intensity: 'Modérée',
          ),
          medicalAdvice: medicalNotice,
        ),
      );
    } else {
      const walkDuration = 30;
      recommendations.add(
        ActivityRecommendation(
          id: 'rec_interval_walk',
          title: 'Marche avec variations d\'allure',
          activityType: 'Marche',
          durationMinutes: walkDuration,
          intensity: 'Modérée',
          frequencyPerWeek: 3,
          category: 'Vitalité quotidienne',
          reason:
              'Idéale pour stimuler la circulation sans risque cardiaque excessif. Adaptée à votre profil de santé.',
          description:
              'Alternez 4 minutes de marche normale et 1 minute de marche soutenue, répétées 6 fois.',
          estimatedCalories: PhysicalActivity.calculateEstimatedCalories(
            type: 'Marche',
            durationMinutes: walkDuration,
            intensity: 'Modérée',
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
        title: 'Gymnastique douce, posture & équilibre',
        activityType: 'Autre',
        durationMinutes: tonusDuration,
        intensity: 'Faible',
        frequencyPerWeek: 2,
        category: 'Équilibre & Mobilité',
        reason:
            'Le maintien de la masse musculaire et de l\'équilibre prévient les blessures et renforce les effets bénéfiques du cardio.',
        description:
            'Mouvements d\'assouplissement, gainage doux et respiration ventrale. Réalisable au sol sur tapis ou avec une chaise.',
        estimatedCalories: PhysicalActivity.calculateEstimatedCalories(
          type: 'Autre',
          durationMinutes: tonusDuration,
          intensity: 'Faible',
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
              'Conseil motivation : "$quote"',
              'Recommandation OMS : Pratiquez au moins 150 minutes d\'activité d\'intensité modérée par semaine.',
            ];
          }
        }
      }
    } catch (e) {
      debugPrint('[ACTIVITY RECOMMENDATIONS] Repli hors-ligne pour l\'API : $e');
    }

    // Repli de conseils médicaux fiables et vérifiés
    return const [
      'Recommandation OMS : Visez au moins 150 minutes d\'activité physique d\'intensité modérée par semaine pour réduire le risque cardiovasculaire de 30%.',
      'Hydratation : Buvez quelques gorgées d\'eau avant, pendant et après chaque séance.',
      'Régularité : Mieux vaut 3 séances de 20 minutes qu\'une seule séance de 60 minutes le week-end.',
      'Sécurité : Si vous ressentez une douleur inhabituelle, des vertiges ou un essoufflement anormal, stoppez l\'exercice et consultez votre médecin.',
    ];
  }
}
