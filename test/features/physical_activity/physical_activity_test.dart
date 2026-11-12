import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meditrackmobile/features/auth/models/user.dart';
import 'package:meditrackmobile/features/physical_activity/models/activity_recommendation.dart';
import 'package:meditrackmobile/features/physical_activity/models/activity_reminder_settings.dart';
import 'package:meditrackmobile/features/physical_activity/models/daily_motivation.dart';
import 'package:meditrackmobile/features/physical_activity/models/physical_activity.dart';
import 'package:meditrackmobile/features/physical_activity/services/activity_recommendation_service.dart';
import 'package:meditrackmobile/features/physical_activity/services/activity_reminder_service.dart';
import 'package:meditrackmobile/features/physical_activity/services/activity_service.dart';
import 'package:meditrackmobile/features/physical_activity/services/motivation_service.dart';

void main() {
  group('PhysicalActivity Model Tests', () {
    test('Création et conversion toMap() / fromMap() avec userId String', () {
      final date = DateTime(2026, 10, 22, 14, 30);
      final activity = PhysicalActivity(
        id: 1,
        userId: 'user_mongodb_123',
        type: 'Course',
        durationMinutes: 45,
        distanceKm: 6.5,
        intensity: 'Élevée',
        activityDate: date,
        notes: 'Bonne séance matinale',
        caloriesBurned: 480,
      );

      final map = activity.toMap();
      expect(map['id'], 1);
      expect(map['user_id'], 'user_mongodb_123');
      expect(map['type'], 'Course');
      expect(map['duration_minutes'], 45);
      expect(map['distance_km'], 6.5);
      expect(map['intensity'], 'Élevée');
      expect(map['activity_date'], date.toIso8601String());
      expect(map['notes'], 'Bonne séance matinale');
      expect(map['calories_burned'], 480);

      final reconstructed = PhysicalActivity.fromMap(map);
      expect(reconstructed.id, activity.id);
      expect(reconstructed.userId, 'user_mongodb_123');
      expect(reconstructed.type, activity.type);
      expect(reconstructed.durationMinutes, activity.durationMinutes);
      expect(reconstructed.distanceKm, activity.distanceKm);
      expect(reconstructed.intensity, activity.intensity);
      expect(reconstructed.activityDate, activity.activityDate);
      expect(reconstructed.notes, activity.notes);
      expect(reconstructed.caloriesBurned, activity.caloriesBurned);
    });

    test('Support de la rétro-compatibilité avec un user_id entier', () {
      final map = {
        'id': 2,
        'user_id': 42, // Ancien format entier en base
        'type': 'Marche',
        'duration_minutes': 30,
        'distance_km': 2.5,
        'intensity': 'Faible',
        'activity_date': DateTime(2026, 11, 1).toIso8601String(),
      };

      final activity = PhysicalActivity.fromMap(map);
      expect(activity.userId, '42'); // Converti proprement en String
    });

    test('Calcul des métriques dérivées : allure (pace) et vitesse', () {
      final running = PhysicalActivity(
        type: 'Course',
        durationMinutes: 30,
        distanceKm: 6.0,
        intensity: 'Modérée',
        activityDate: DateTime.now(),
      );

      expect(running.paceLabel, "5'00\"/km");
      expect(running.speedKmh, 12.0);

      final walking = PhysicalActivity(
        type: 'Marche',
        durationMinutes: 45,
        distanceKm: 3.8,
        intensity: 'Faible',
        activityDate: DateTime.now(),
      );

      expect(walking.paceLabel, isNotNull);
      expect(walking.speedKmh, closeTo(5.06, 0.05));
    });

    test('Estimation automatique des calories (formule MET)', () {
      // Marche 60 min, intensité modérée (MET 3.6, poids 70 kg) -> 3.6 * 70 * 1 = 252 kcal
      final calMarche = PhysicalActivity.calculateEstimatedCalories(
        type: 'Marche',
        durationMinutes: 60,
        intensity: 'Modérée',
      );
      expect(calMarche, 252);

      // Course 30 min, intensité élevée (MET 11.5, poids 70 kg) -> 11.5 * 70 * 0.5 = 403 kcal
      final calCourse = PhysicalActivity.calculateEstimatedCalories(
        type: 'Course',
        durationMinutes: 30,
        intensity: 'Élevée',
      );
      expect(calCourse, 403);

      // Durée 0 -> 0 kcal
      final calZero = PhysicalActivity.calculateEstimatedCalories(
        type: 'Vélo',
        durationMinutes: 0,
        intensity: 'Faible',
      );
      expect(calZero, 0);
    });

    test('ActivityWeeklySummary calcule correctement la progression vers l\'objectif OMS', () {
      const summaryUnder = ActivityWeeklySummary(
        totalMinutes: 90,
        totalCalories: 450,
        totalDistanceKm: 10.0,
        sessionCount: 2,
        weeklyGoalMinutes: 150,
      );

      expect(summaryUnder.goalProgress, closeTo(0.6, 0.01));
      expect(summaryUnder.goalAchieved, isFalse);

      const summaryOver = ActivityWeeklySummary(
        totalMinutes: 180,
        totalCalories: 900,
        totalDistanceKm: 20.0,
        sessionCount: 4,
        weeklyGoalMinutes: 150,
      );

      expect(summaryOver.goalProgress, 1.0);
      expect(summaryOver.goalAchieved, isTrue);
    });

    test('Support des valeurs facultatives nulles', () {
      final date = DateTime.now();
      final activity = PhysicalActivity(
        type: 'Marche',
        durationMinutes: 30,
        intensity: 'Faible',
        activityDate: date,
      );

      expect(activity.id, isNull);
      expect(activity.userId, isNull);
      expect(activity.distanceKm, isNull);
      expect(activity.notes, isNull);
      expect(activity.caloriesBurned, isNull);
      expect(activity.paceLabel, isNull);
      expect(activity.speedKmh, isNull);

      final map = activity.toMap();
      final reconstructed = PhysicalActivity.fromMap(map);
      expect(reconstructed.distanceKm, isNull);
      expect(reconstructed.notes, isNull);
      expect(reconstructed.caloriesBurned, isNull);
    });

    test('copyWith() modifie uniquement les champs cibles', () {
      final activity = PhysicalActivity(
        id: 10,
        type: 'Vélo',
        durationMinutes: 60,
        distanceKm: 20.0,
        intensity: 'Modérée',
        activityDate: DateTime(2026, 10, 20),
      );

      final updated = activity.copyWith(
        durationMinutes: 75,
        distanceKm: 25.0,
        caloriesBurned: 400,
      );

      expect(updated.id, 10);
      expect(updated.type, 'Vélo');
      expect(updated.durationMinutes, 75);
      expect(updated.distanceKm, 25.0);
      expect(updated.intensity, 'Modérée');
      expect(updated.caloriesBurned, 400);
    });
  });

  group('Smart Session Reminders Tests (-5 minutes)', () {
    test('Valeurs par défaut : activé avec 5 minutes d\'avance', () {
      const settings = ActivityReminderSettings();

      expect(settings.enabled, isTrue);
      expect(settings.leadTimeMinutes, 5);
    });

    test('calculateReminderTime() calcule exactement 5 minutes avant la séance', () {
      const settings = ActivityReminderSettings(); // 5 min
      final sessionDate = DateTime(2026, 11, 11, 10, 0); // Demain à 10h00
      final reminderTime = settings.calculateReminderTime(sessionDate);

      expect(reminderTime, DateTime(2026, 11, 11, 9, 55)); // Exactement 09h55
    });

    test('isReminderInFuture() valide correctement si le rappel est futur ou déjà passé', () {
      const settings = ActivityReminderSettings(); // 5 min
      final now = DateTime(2026, 11, 10, 12, 0); // Référence : 12h00

      // Séance demain à 10h00 -> rappel demain à 09h55 (> 12h00) -> true
      final futureSession = DateTime(2026, 11, 11, 10, 0);
      expect(settings.isReminderInFuture(futureSession, now), isTrue);

      // Séance passée hier -> false
      final pastSession = DateTime(2026, 11, 9, 15, 0);
      expect(settings.isReminderInFuture(pastSession, now), isFalse);

      // Séance dans 3 minutes (12h03) -> rappel à 11h58 (< 12h00) -> false
      final tooCloseSession = DateTime(2026, 11, 10, 12, 3);
      expect(settings.isReminderInFuture(tooCloseSession, now), isFalse);

      // Séance dans 10 minutes (12h10) -> rappel à 12h05 (> 12h00) -> true
      final validUpcomingSession = DateTime(2026, 11, 10, 12, 10);
      expect(settings.isReminderInFuture(validUpcomingSession, now), isTrue);
    });

    test('Sérialisation toMap() et désérialisation fromMap()', () {
      const original = ActivityReminderSettings(
        enabled: false,
        leadTimeMinutes: 10,
      );

      final map = original.toMap();
      expect(map['enabled'], isFalse);
      expect(map['leadTimeMinutes'], 10);

      final reconstructed = ActivityReminderSettings.fromMap(map);
      expect(reconstructed.enabled, isFalse);
      expect(reconstructed.leadTimeMinutes, 10);
    });

    test('fromMap() avec map vide utilise les valeurs par défaut fiables', () {
      final parsed = ActivityReminderSettings.fromMap(const {});

      expect(parsed.enabled, isTrue);
      expect(parsed.leadTimeMinutes, 5);
    });

    test('copyWith() modifie uniquement les champs cibles', () {
      const initial = ActivityReminderSettings();

      final updated = initial.copyWith(enabled: false);
      expect(updated.enabled, isFalse);
      expect(updated.leadTimeMinutes, 5); // Inchangé
    });

    test('ActivityReminderService génère des IDs de notification uniques et isolés', () {
      final service = ActivityReminderService.instance;

      expect(service.notificationIdForActivity(1), 30001);
      expect(service.notificationIdForActivity(42), 30042);
      expect(service.notificationIdForActivity(105), 30105);
      expect(service.notificationIdForActivity(1) != service.notificationIdForActivity(2), isTrue);
    });
  });

  group('Sports Agenda Logic Tests', () {
    test('Filtrage des séances par jour spécifique dans l\'agenda', () {
      final act1 = PhysicalActivity(
        id: 1,
        type: 'Course',
        durationMinutes: 45,
        intensity: 'Élevée',
        activityDate: DateTime(2026, 11, 12, 9, 30),
      );

      final act2 = PhysicalActivity(
        id: 2,
        type: 'Marche',
        durationMinutes: 30,
        intensity: 'Faible',
        activityDate: DateTime(2026, 11, 12, 17, 0),
      );

      final act3 = PhysicalActivity(
        id: 3,
        type: 'Vélo',
        durationMinutes: 60,
        intensity: 'Modérée',
        activityDate: DateTime(2026, 11, 15, 14, 0),
      );

      final all = [act1, act2, act3];
      final targetDay = DateTime(2026, 11, 12);

      bool isSameDay(DateTime a, DateTime b) =>
          a.year == b.year && a.month == b.month && a.day == b.day;

      final daySessions = all.where((a) => isSameDay(a.activityDate, targetDay)).toList();

      expect(daySessions.length, 2);
      expect(daySessions.map((a) => a.id), containsAll([1, 2]));
    });

    test('Distinction des séances passées et futures dans le calendrier', () {
      final referenceNow = DateTime(2026, 11, 10, 12, 0);

      final pastActivity = PhysicalActivity(
        type: 'Marche',
        durationMinutes: 30,
        intensity: 'Faible',
        activityDate: DateTime(2026, 11, 9, 10, 0),
      );

      final futureActivity = PhysicalActivity(
        type: 'Course',
        durationMinutes: 45,
        intensity: 'Modérée',
        activityDate: DateTime(2026, 11, 11, 10, 0),
      );

      expect(pastActivity.activityDate.isBefore(referenceNow), isTrue);
      expect(futureActivity.activityDate.isAfter(referenceNow), isTrue);
    });

    test('Calcul des jours avec indicateur de séance pour un mois donné', () {
      final activities = [
        PhysicalActivity(
          type: 'Course',
          durationMinutes: 30,
          intensity: 'Modérée',
          activityDate: DateTime(2026, 11, 5, 8, 0),
        ),
        PhysicalActivity(
          type: 'Natation',
          durationMinutes: 45,
          intensity: 'Élevée',
          activityDate: DateTime(2026, 11, 5, 18, 0),
        ),
        PhysicalActivity(
          type: 'Marche',
          durationMinutes: 60,
          intensity: 'Faible',
          activityDate: DateTime(2026, 11, 20, 11, 0),
        ),
        PhysicalActivity(
          type: 'Vélo',
          durationMinutes: 90,
          intensity: 'Élevée',
          activityDate: DateTime(2026, 12, 1, 10, 0), // Mois suivant
        ),
      ];

      // Jours uniques avec séances en Novembre 2026
      final novemberDaysWithActivities = activities
          .where((a) => a.activityDate.year == 2026 && a.activityDate.month == 11)
          .map((a) => a.activityDate.day)
          .toSet();

      expect(novemberDaysWithActivities, equals({5, 20}));
      expect(novemberDaysWithActivities.contains(1), isFalse);
    });
  });

  group('Personalized Recommendations Engine Tests', () {
    final service = ActivityRecommendationService.instance;

    test('Modèle ActivityRecommendation toMap() / fromMap() et getters visuels', () {
      const rec = ActivityRecommendation(
        id: 'rec_test',
        title: 'Marche active',
        activityType: 'Marche',
        durationMinutes: 30,
        intensity: 'Modérée',
        frequencyPerWeek: 3,
        category: 'Cardio santé',
        reason: 'Amélioration de l\'endurance',
        description: 'Marche rapide sur terrain plat',
        estimatedCalories: 150,
        medicalAdvice: 'Avis médical conseillé',
      );

      expect(rec.icon, isNotNull);
      expect(rec.intensityColor, isNotNull);

      final map = rec.toMap();
      expect(map['title'], 'Marche active');
      expect(map['durationMinutes'], 30);
      expect(map['estimatedCalories'], 150);

      final parsed = ActivityRecommendation.fromMap(map);
      expect(parsed.title, rec.title);
      expect(parsed.activityType, rec.activityType);
      expect(parsed.durationMinutes, rec.durationMinutes);
      expect(parsed.intensity, rec.intensity);
      expect(parsed.medicalAdvice, 'Avis médical conseillé');
    });

    test('Patient débutant / sédentaire (< 60 min) reçoit une reprise en douceur adaptée', () {
      final user = User(
        nom: 'Dupont',
        prenom: 'Jean',
        email: 'jean.dupont@meditrack.fr',
        dateNaissance: '1990-05-15', // 36 ans
      );

      const summary = ActivityWeeklySummary(
        totalMinutes: 0,
        totalCalories: 0,
        totalDistanceKm: 0.0,
        sessionCount: 0,
      );

      final recs = service.generateRecommendations(
        user: user,
        history: [],
        summary: summary,
      );

      expect(recs.isNotEmpty, isTrue);
      final primary = recs.first;
      expect(primary.category, 'Gentle Restart');
      expect(primary.activityType, 'Walking');
      expect(primary.durationMinutes, 25);
      expect(primary.intensity, 'Low');
    });

    test('Patient en progression (60 à 149 min) reçoit une recommandation Objectif OMS 150 min', () {
      final user = User(
        nom: 'Martin',
        prenom: 'Claire',
        email: 'claire.martin@meditrack.fr',
        dateNaissance: '1985-02-10',
      );

      final history = [
        PhysicalActivity(
          type: 'Marche',
          durationMinutes: 45,
          intensity: 'Modérée',
          activityDate: DateTime(2026, 11, 2),
        ),
        PhysicalActivity(
          type: 'Marche',
          durationMinutes: 45,
          intensity: 'Modérée',
          activityDate: DateTime(2026, 11, 5),
        ),
      ];

      const summary = ActivityWeeklySummary(
        totalMinutes: 90,
        totalCalories: 380,
        totalDistanceKm: 7.5,
        sessionCount: 2,
      );

      final recs = service.generateRecommendations(
        user: user,
        history: history,
        summary: summary,
      );

      final primary = recs.first;
      expect(primary.category, 'WHO Progression');
      // 150 - 90 = 60 min restantes, clampé à 45 max par séance
      expect(primary.durationMinutes, 45);
      expect(primary.intensity, 'Moderate');
    });

    test('Patient actif (>= 150 min) reçoit une recommandation de maintien et consolidation', () {
      final user = User(
        nom: 'Bernard',
        prenom: 'Alex',
        email: 'alex.bernard@meditrack.fr',
      );

      const summary = ActivityWeeklySummary(
        totalMinutes: 180,
        totalCalories: 950,
        totalDistanceKm: 18.0,
        sessionCount: 3,
      );

      final recs = service.generateRecommendations(
        user: user,
        history: [
          PhysicalActivity(
            type: 'Course',
            durationMinutes: 60,
            intensity: 'Modérée',
            activityDate: DateTime(2026, 11, 4),
          ),
        ],
        summary: summary,
      );

      final primary = recs.first;
      expect(primary.category, contains('WHO Goal Achieved'));
      expect(primary.activityType, 'Running'); // Identifie le sport favori
    });

    test('Patient avec condition médicale : intensité plafonnée et avis médical obligatoire', () {
      final user = User(
        nom: 'Leroy',
        prenom: 'Marc',
        email: 'marc.leroy@meditrack.fr',
        dateNaissance: '1975-08-20',
        conditionMedicale: 'Hypertension artérielle',
      );

      const summary = ActivityWeeklySummary(
        totalMinutes: 160,
        totalCalories: 800,
        totalDistanceKm: 12.0,
        sessionCount: 3,
      );

      final recs = service.generateRecommendations(
        user: user,
        history: [],
        summary: summary,
      );

      // Vérifie que chaque recommandation contient la mise en garde médicale
      for (final rec in recs) {
        expect(rec.medicalAdvice, isNotNull);
        expect(rec.medicalAdvice, contains('Hypertension artérielle'));
        expect(rec.medicalAdvice, contains('attending physician'));
        // L'intensité ne doit pas être 'High' pour un patient avec condition médicale déclarée
        expect(rec.intensity != 'High', isTrue);
      }
    });

    test('Patient senior (>= 65 ans) reçoit un conseil de pratique douce sans impact excessif', () {
      final senior = User(
        nom: 'Dubois',
        prenom: 'Paul',
        email: 'paul.dubois@meditrack.fr',
        dateNaissance: '1950-01-01', // > 75 ans
      );

      const summary = ActivityWeeklySummary(
        totalMinutes: 100,
        totalCalories: 400,
        totalDistanceKm: 6.0,
        sessionCount: 2,
      );

      final recs = service.generateRecommendations(
        user: senior,
        history: [],
        summary: summary,
      );

      final primary = recs.first;
      expect(primary.medicalAdvice, isNotNull);
      expect(primary.medicalAdvice!.toLowerCase(), contains('senior'));
      // Doit proposer une activité sans à-coups (Walking ou Cycling)
      expect(['Walking', 'Cycling', 'Swimming'].contains(primary.activityType), isTrue);
    });

    test('fetchExternalHealthTips() retourne des conseils médicaux valides même hors-ligne', () async {
      final tips = await service.fetchExternalHealthTips();
      expect(tips.isNotEmpty, isTrue);
      expect(tips.any((t) => t.contains('WHO')), isTrue);
    });
  });

  group('Reactivity and thisMonthCount Tests', () {
    test('ActivityService.changeNotifier notifie correctement ses écouteurs', () {
      int notificationsReceived = 0;
      void listener() {
        notificationsReceived++;
      }

      ActivityService.changeNotifier.addListener(listener);

      expect(notificationsReceived, 0);
      ActivityService.changeNotifier.notify();
      expect(notificationsReceived, 1);

      ActivityService.changeNotifier.notify();
      expect(notificationsReceived, 2);

      ActivityService.changeNotifier.removeListener(listener);
      ActivityService.changeNotifier.notify();
      expect(notificationsReceived, 2); // Ne reçoit plus de notifications après désinscription
    });

    test('Calcul de thisMonthCount filtre strictement le mois et l\'année en cours', () {
      final now = DateTime(2026, 11, 10);

      final activities = [
        // Séances du mois en cours (Novembre 2026) -> DOIVENT être comptées
        PhysicalActivity(
          id: 1,
          type: 'Course',
          durationMinutes: 30,
          intensity: 'Modérée',
          activityDate: DateTime(2026, 11, 2, 8, 30),
        ),
        PhysicalActivity(
          id: 2,
          type: 'Marche',
          durationMinutes: 45,
          intensity: 'Faible',
          activityDate: DateTime(2026, 11, 28, 17, 0),
        ),
        // Séance du mois précédent (Octobre 2026) -> NE DOIT PAS être comptée
        PhysicalActivity(
          id: 3,
          type: 'Vélo',
          durationMinutes: 60,
          intensity: 'Modérée',
          activityDate: DateTime(2026, 10, 31, 23, 59),
        ),
        // Séance du mois suivant (Décembre 2026) -> NE DOIT PAS être comptée
        PhysicalActivity(
          id: 4,
          type: 'Natation',
          durationMinutes: 45,
          intensity: 'Élevée',
          activityDate: DateTime(2026, 12, 1, 9, 0),
        ),
        // Séance de la même date mais l'année passée (Novembre 2025) -> NE DOIT PAS être comptée
        PhysicalActivity(
          id: 5,
          type: 'Marche',
          durationMinutes: 30,
          intensity: 'Faible',
          activityDate: DateTime(2025, 11, 10, 10, 0),
        ),
      ];

      int calculateMonthCount(List<PhysicalActivity> list, DateTime ref) {
        return list.where((a) {
          final d = a.activityDate.toLocal();
          return d.year == ref.year && d.month == ref.month;
        }).length;
      }

      final count = calculateMonthCount(activities, now);
      expect(count, 2); // Exactement les 2 séances de Novembre 2026
    });

    test('Évolution dynamique de thisMonthCount lors d\'ajouts, modifications et suppressions', () {
      final now = DateTime(2026, 11, 10);
      final list = <PhysicalActivity>[
        PhysicalActivity(
          id: 1,
          type: 'Marche',
          durationMinutes: 30,
          intensity: 'Faible',
          activityDate: DateTime(2026, 11, 5),
        ),
      ];

      int getCount() => list.where((a) {
            final d = a.activityDate.toLocal();
            return d.year == now.year && d.month == now.month;
          }).length;

      // 1. Initial : 1 séance
      expect(getCount(), 1);

      // 2. Ajout d'une séance dans le mois en cours
      final newAct = PhysicalActivity(
        id: 2,
        type: 'Course',
        durationMinutes: 45,
        intensity: 'Modérée',
        activityDate: DateTime(2026, 11, 11),
      );
      list.add(newAct);
      expect(getCount(), 2); // Immédiatement 2

      // 3. Modification de la date vers un autre mois (ex: reportée à Décembre)
      final index = list.indexWhere((a) => a.id == 2);
      list[index] = newAct.copyWith(activityDate: DateTime(2026, 12, 1));
      expect(getCount(), 1); // Redescend immédiatement à 1

      // 4. Suppression de la dernière séance du mois
      list.removeWhere((a) => a.id == 1);
      expect(getCount(), 0); // Passe immédiatement à 0
    });
  });

  group('ZenQuotes API and Daily Motivation Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('DailyMotivation.fromZenQuotesJson() parse correctement le JSON retourné par l\'API', () {
      final json = {
        'q': 'It does not matter how slowly you go as long as you do not stop.',
        'a': 'Confucius',
        'h': '<blockquote>...</blockquote>',
      };

      final motivation = DailyMotivation.fromZenQuotesJson(json);

      expect(motivation.quote, 'It does not matter how slowly you go as long as you do not stop.');
      expect(motivation.author, 'Confucius');
      expect(motivation.category, 'Daily motivation');
      expect(motivation.isFromApi, isTrue);
    });

    test('DailyMotivation.fromZenQuotesJson() applique les valeurs par défaut en cas de champs manquants', () {
      final json = <String, dynamic>{};
      final motivation = DailyMotivation.fromZenQuotesJson(json);

      expect(motivation.quote.isNotEmpty, isTrue);
      expect(motivation.author, 'ZenQuotes');
      expect(motivation.isFromApi, isTrue);
    });

    test('Sérialisation toMap() / fromMap() et JSON round-trip de DailyMotivation', () {
      final now = DateTime(2026, 11, 10, 8, 0);
      final motivation = DailyMotivation(
        quote: 'La marche est le meilleur remède de l’homme.',
        author: 'Hippocrate',
        category: 'Santé & Longévité',
        date: now,
        isFromApi: false,
      );

      final map = motivation.toMap();
      expect(map['quote'], 'La marche est le meilleur remède de l’homme.');
      expect(map['author'], 'Hippocrate');
      expect(map['category'], 'Santé & Longévité');
      expect(map['isFromApi'], 0);

      final restored = DailyMotivation.fromMap(map);
      expect(restored.quote, motivation.quote);
      expect(restored.author, motivation.author);
      expect(restored.category, motivation.category);
      expect(restored.isFromApi, isFalse);

      final jsonString = motivation.toJson();
      final fromJson = DailyMotivation.fromJson(jsonString);
      expect(fromJson.quote, motivation.quote);
      expect(fromJson.author, motivation.author);
    });

    test('copyWith() modifie uniquement les attributs spécifiés', () {
      final original = DailyMotivation(
        quote: 'Citation test',
        author: 'Auteur initial',
        category: 'Catégorie initiale',
        isFromApi: false,
      );

      final updated = original.copyWith(
        quote: 'Nouvelle citation',
        isFromApi: true,
      );

      expect(updated.quote, 'Nouvelle citation');
      expect(updated.author, 'Auteur initial');
      expect(updated.category, 'Catégorie initiale');
      expect(updated.isFromApi, isTrue);
    });

    test('MotivationService.getLocalFallback() retourne des citations sport-santé valides et bienveillantes', () {
      final service = MotivationService.instance;
      final fallback = service.getLocalFallback(DateTime(2026, 11, 10));

      expect(fallback.quote.isNotEmpty, isTrue);
      expect(fallback.author.isNotEmpty, isTrue);
      expect(fallback.category.isNotEmpty, isTrue);
      expect(fallback.isFromApi, isFalse);
    });

    test('MotivationService consomme avec succès l\'API ZenQuotes via MockClient (Status 200)', () async {
      final mockClient = MockClient((request) async {
        final mockResponse = [
          {
            'q': 'Believe you can and you are halfway there.',
            'a': 'Theodore Roosevelt',
            'h': '<blockquote>...</blockquote>',
          }
        ];
        return http.Response(jsonEncode(mockResponse), 200, headers: {'content-type': 'application/json'});
      });

      final service = MotivationService.instance;
      final result = await service.getDailyMotivation(forceRefresh: true, client: mockClient);

      expect(result.quote, 'Believe you can and you are halfway there.');
      expect(result.author, 'Theodore Roosevelt');
      expect(result.isFromApi, isTrue);
    });

    test('MotivationService bascule automatiquement sur le repli sport-santé en cas d\'erreur réseau (Status 500)', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = MotivationService.instance;
      final result = await service.getDailyMotivation(forceRefresh: true, client: mockClient);

      expect(result.quote.isNotEmpty, isTrue);
      expect(result.isFromApi, isFalse); // Repli local
    });

    test('MotivationService détecte le message de limitation de requêtes ZenQuotes et applique le repli', () async {
      final mockClient = MockClient((request) async {
        final rateLimitResponse = [
          {
            'q': 'Too many requests. Please wait a few seconds before trying again.',
            'a': 'zenquotes.io',
          }
        ];
        return http.Response(jsonEncode(rateLimitResponse), 200, headers: {'content-type': 'application/json'});
      });

      final service = MotivationService.instance;
      final result = await service.getDailyMotivation(forceRefresh: true, client: mockClient);

      // Ne doit pas afficher le message d'erreur brut au patient mais un repli élégant
      expect(result.quote.contains('Too many requests'), isFalse);
      expect(result.isFromApi, isFalse);
    });

    test('MotivationService met en cache le conseil du jour et évite les requêtes réseau superflues', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        final mockResponse = [
          {
            'q': 'Keep your face always toward the sunshine.',
            'a': 'Walt Whitman',
          }
        ];
        return http.Response(jsonEncode(mockResponse), 200, headers: {'content-type': 'application/json'});
      });

      final service = MotivationService.instance;
      await service.clearCache();

      // 1er appel : forceRefresh -> requête réseau
      final first = await service.getDailyMotivation(forceRefresh: true, client: mockClient);
      expect(requestCount, 1);
      expect(first.quote, 'Keep your face always toward the sunshine.');

      // 2e appel : appel normal sans forceRefresh -> chargé depuis le cache SharedPreferences
      final second = await service.getDailyMotivation(forceRefresh: false, client: mockClient);
      expect(requestCount, 1); // Aucun appel réseau supplémentaire !
      expect(second.quote, first.quote);
      expect(second.author, first.author);

      // 3e appel : utilisateur demande explicitement un rafraîchissement (forceRefresh: true)
      await service.getDailyMotivation(forceRefresh: true, client: mockClient);
      expect(requestCount, 2); // Appel réseau effectué
    });
  });
}
