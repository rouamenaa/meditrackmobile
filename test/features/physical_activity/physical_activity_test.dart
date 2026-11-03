import 'package:flutter_test/flutter_test.dart';
import 'package:meditrackmobile/features/physical_activity/models/physical_activity.dart';

void main() {
  group('PhysicalActivity Model Tests', () {
    test('Création et conversion toMap() / fromMap()', () {
      final date = DateTime(2026, 10, 22, 14, 30);
      final activity = PhysicalActivity(
        id: 1,
        userId: 42,
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
      expect(map['user_id'], 42);
      expect(map['type'], 'Course');
      expect(map['duration_minutes'], 45);
      expect(map['distance_km'], 6.5);
      expect(map['intensity'], 'Élevée');
      expect(map['activity_date'], date.toIso8601String());
      expect(map['notes'], 'Bonne séance matinale');
      expect(map['calories_burned'], 480);

      final reconstructed = PhysicalActivity.fromMap(map);
      expect(reconstructed.id, activity.id);
      expect(reconstructed.userId, activity.userId);
      expect(reconstructed.type, activity.type);
      expect(reconstructed.durationMinutes, activity.durationMinutes);
      expect(reconstructed.distanceKm, activity.distanceKm);
      expect(reconstructed.intensity, activity.intensity);
      expect(reconstructed.activityDate, activity.activityDate);
      expect(reconstructed.notes, activity.notes);
      expect(reconstructed.caloriesBurned, activity.caloriesBurned);
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
}
