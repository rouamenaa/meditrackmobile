import 'package:flutter_test/flutter_test.dart';
import 'package:meditrackmobile/features/physical_activity/models/activity_reminder_settings.dart';
import 'package:meditrackmobile/features/physical_activity/models/physical_activity.dart';
import 'package:meditrackmobile/features/physical_activity/services/activity_reminder_service.dart';
import 'package:meditrackmobile/features/physical_activity/services/activity_service.dart';

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
}
