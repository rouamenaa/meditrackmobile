import 'package:flutter_test/flutter_test.dart';
import 'package:meditrackmobile/features/treatments/models/treatment.dart';
import 'package:meditrackmobile/features/treatments/repositories/treatment_repository.dart';
import 'package:meditrackmobile/features/treatments/utils/date_fr.dart';

/// Tests du module Traitements (modèles, règles métier et helpers de dates).
///
/// Aucune base SQLite n'est ouverte ici : on teste tout ce qui est calculable
/// sans I/O (sérialisation, statuts, fréquence, progression, formatage FR).

Treatment _treatment({
  int? id = 1,
  String userId = 'user-1',
  String medicationName = 'Doliprane',
  String? medicationDosage = '500 mg',
  String dose = '1 comprimé',
  List<String> reminderTimes = const ['08:00', '20:00'],
  DateTime? startDate,
  DateTime? endDate,
  TreatmentStatus status = TreatmentStatus.active,
}) {
  return Treatment(
    id: id,
    userId: userId,
    medicationName: medicationName,
    medicationDosage: medicationDosage,
    dose: dose,
    reminderTimes: reminderTimes,
    startDate: startDate ?? DateTime(2026, 11, 1),
    endDate: endDate,
    status: status,
  );
}

void main() {
  group('Conversion des statuts', () {
    test('treatmentStatusFromString reconnaît tous les états', () {
      expect(treatmentStatusFromString('planned'), TreatmentStatus.planned);
      expect(treatmentStatusFromString('active'), TreatmentStatus.active);
      expect(treatmentStatusFromString('stopped'), TreatmentStatus.stopped);
      expect(treatmentStatusFromString('completed'), TreatmentStatus.completed);
    });

    test('treatmentStatusFromString retourne "planned" par défaut', () {
      expect(treatmentStatusFromString('inconnu'), TreatmentStatus.planned);
      expect(treatmentStatusFromString('ACTIVE'), TreatmentStatus.planned);
      expect(treatmentStatusFromString(''), TreatmentStatus.planned);
    });

    test('intakeStatusFromString reconnaît tous les états', () {
      expect(intakeStatusFromString('pending'), IntakeStatus.pending);
      expect(intakeStatusFromString('taken'), IntakeStatus.taken);
      expect(intakeStatusFromString('missed'), IntakeStatus.missed);
      expect(intakeStatusFromString('skipped'), IntakeStatus.skipped);
    });

    test('intakeStatusFromString retourne "pending" par défaut', () {
      expect(intakeStatusFromString('inconnu'), IntakeStatus.pending);
      expect(intakeStatusFromString('TAKEN'), IntakeStatus.pending);
      expect(intakeStatusFromString(''), IntakeStatus.pending);
    });
  });

  group('Treatment — sérialisation', () {
    test('toMap encode les champs et les dates sans heure', () {
      final t = _treatment(
        id: 42,
        userId: 'user-abc',
        startDate: DateTime(2026, 11, 1, 15, 30),
        endDate: DateTime(2026, 11, 30, 18),
      );

      final map = t.toMap();

      expect(map['id'], 42);
      expect(map['user_id'], 'user-abc');
      expect(map['medication_name'], 'Doliprane');
      expect(map['medication_dosage'], '500 mg');
      expect(map['dose'], '1 comprimé');
      expect(map['reminder_times'], '08:00,20:00');
      expect(map['start_date'], '2026-11-01');
      expect(map['end_date'], '2026-11-30');
      expect(map['status'], 'active');
    });

    test('fromMap reconstruit un traitement complet', () {
      final t = Treatment.fromMap({
        'id': 42,
        'user_id': 'user-abc',
        'medication_name': 'Doliprane',
        'medication_dosage': '500 mg',
        'dose': '1 comprimé',
        'reminder_times': '08:00,20:00',
        'start_date': '2026-11-01',
        'end_date': '2026-11-30',
        'status': 'active',
      });

      expect(t.id, 42);
      expect(t.userId, 'user-abc');
      expect(t.medicationName, 'Doliprane');
      expect(t.medicationDosage, '500 mg');
      expect(t.dose, '1 comprimé');
      expect(t.reminderTimes, ['08:00', '20:00']);
      expect(t.startDate, DateTime(2026, 11, 1));
      expect(t.endDate, DateTime(2026, 11, 30));
      expect(t.status, TreatmentStatus.active);
    });

    test('aller-retour toMap / fromMap conserve les valeurs', () {
      final original = _treatment(
        id: 7,
        userId: 'user-x',
        reminderTimes: ['07:30', '12:00', '21:15'],
        startDate: DateTime(2026, 3, 5),
        endDate: DateTime(2026, 4, 5),
        status: TreatmentStatus.planned,
      );

      final copie = Treatment.fromMap(original.toMap());

      expect(copie.id, original.id);
      expect(copie.userId, original.userId);
      expect(copie.medicationName, original.medicationName);
      expect(copie.medicationDosage, original.medicationDosage);
      expect(copie.dose, original.dose);
      expect(copie.reminderTimes, original.reminderTimes);
      expect(copie.startDate, original.startDate);
      expect(copie.endDate, original.endDate);
      expect(copie.status, original.status);
    });

    test('traitement chronique : end_date null', () {
      final t = _treatment(endDate: null);

      expect(t.isChronic, true);
      expect(t.toMap()['end_date'], isNull);
      expect(Treatment.fromMap(t.toMap()).endDate, isNull);
    });

    test('dates ISO avec heure et dose facultative nulle', () {
      final t = Treatment.fromMap({
        'id': 3,
        'user_id': 12,
        'medication_name': 'Ibuprofène',
        'medication_dosage': null,
        'dose': '2 comprimés',
        'reminder_times': '08:00',
        'start_date': '2026-11-01T00:00:00.000',
        'end_date': '2026-11-10T23:59:59.000',
        'status': 'stopped',
      });

      expect(t.userId, '12'); // toujours converti en String
      expect(t.medicationDosage, isNull);
      expect(t.startDate, DateTime(2026, 11, 1));
      expect(t.endDate, DateTime(2026, 11, 10));
      expect(t.status, TreatmentStatus.stopped);
    });

    test('statut absent -> "active", statut inconnu -> "planned"', () {
      final base = {
        'user_id': 'u',
        'medication_name': 'X',
        'dose': '1',
        'reminder_times': '08:00',
        'start_date': '2026-01-01',
      };

      expect(
        Treatment.fromMap({...base, 'status': null}).status,
        TreatmentStatus.active,
      );
      expect(
        Treatment.fromMap({...base, 'status': 'weird'}).status,
        TreatmentStatus.planned,
      );
    });

    test('reminder_times : espaces supprimés et entrées invalides ignorées', () {
      final t = Treatment.fromMap({
        'user_id': 'u',
        'medication_name': 'X',
        'dose': '1',
        'reminder_times': ' 08:00 , 20:00 ,bad,9:30,,24:00',
        'start_date': '2026-01-01',
      });

      expect(t.reminderTimes, ['08:00', '20:00', '9:30', '24:00']);
    });

    test('reminder_times vide -> liste vide', () {
      final t = Treatment.fromMap({
        'user_id': 'u',
        'medication_name': 'X',
        'dose': '1',
        'reminder_times': '',
        'start_date': '2026-01-01',
      });

      expect(t.reminderTimes, isEmpty);
      expect(t.timesPerDay, 0);
    });
  });

  group('Treatment — règles métier', () {
    test('isActive : vrai pour actif et planifié uniquement', () {
      expect(_treatment(status: TreatmentStatus.active).isActive, true);
      expect(_treatment(status: TreatmentStatus.planned).isActive, true);
      expect(_treatment(status: TreatmentStatus.stopped).isActive, false);
      expect(_treatment(status: TreatmentStatus.completed).isActive, false);
    });

    test('isChronic dépend de la présence d\'une date de fin', () {
      expect(_treatment(endDate: null).isChronic, true);
      expect(_treatment(endDate: DateTime(2026, 12, 31)).isChronic, false);
    });

    test('hasExpiredDate : vrai seulement pour une fin déjà passée', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      expect(
        _treatment(endDate: today.subtract(const Duration(days: 1)))
            .hasExpiredDate,
        true,
      );
      expect(_treatment(endDate: today).hasExpiredDate, false);
      expect(
        _treatment(endDate: today.add(const Duration(days: 1)))
            .hasExpiredDate,
        false,
      );
      expect(_treatment(endDate: null).hasExpiredDate, false);
    });

    test('timesPerDay = nombre d\'horaires', () {
      expect(_treatment(reminderTimes: const []).timesPerDay, 0);
      expect(_treatment(reminderTimes: const ['08:00']).timesPerDay, 1);
      expect(
        _treatment(reminderTimes: const ['08:00', '12:00', '20:00'])
            .timesPerDay,
        3,
      );
    });
  });

  group('Treatment — libellé de fréquence', () {
    test('aucun horaire -> tiret', () {
      expect(_treatment(reminderTimes: const []).frequencyLabel, '—');
    });

    test('une prise le matin', () {
      expect(
        _treatment(reminderTimes: const ['08:00']).frequencyLabel,
        '1x per morning (Morning)',
      );
    });

    test('une prise le soir', () {
      expect(
        _treatment(reminderTimes: const ['20:00']).frequencyLabel,
        '1x per evening (Evening)',
      );
    });

    test('matin + soir', () {
      expect(
        _treatment(reminderTimes: const ['08:00', '20:00']).frequencyLabel,
        '2x per day (Morning & Evening)',
      );
    });

    test('matin + après-midi', () {
      expect(
        _treatment(reminderTimes: const ['09:00', '14:00']).frequencyLabel,
        '2x per day (Morning & Afternoon)',
      );
    });

    test('les moments identiques ne sont pas répétés', () {
      expect(
        _treatment(reminderTimes: const ['08:00', '20:00', '21:00'])
            .frequencyLabel,
        '3x per day (Morning & Evening)',
      );
    });

    test('horaire invalide -> compté mais sans moment', () {
      expect(
        _treatment(reminderTimes: const ['abc']).frequencyLabel,
        '1x per day',
      );
    });

    test('midi et après-midi restent "par jour"', () {
      expect(
        _treatment(reminderTimes: const ['12:00']).frequencyLabel,
        '1x per day (Afternoon)',
      );
    });
  });

  group('IntakeLog — sérialisation', () {
    test('toMap encode les dates en ISO 8601', () {
      final log = IntakeLog(
        id: 9,
        treatmentId: 42,
        scheduledAt: DateTime(2026, 11, 7, 8),
        takenAt: DateTime(2026, 11, 7, 8, 12, 30),
        status: IntakeStatus.taken,
      );

      final map = log.toMap();

      expect(map['id'], 9);
      expect(map['treatment_id'], 42);
      expect(map['scheduled_at'], '2026-11-07T08:00:00.000');
      expect(map['taken_at'], '2026-11-07T08:12:30.000');
      expect(map['status'], 'taken');
    });

    test('fromMap reconstruit une prise en attente', () {
      final log = IntakeLog.fromMap({
        'id': 1,
        'treatment_id': 42,
        'scheduled_at': '2026-11-07T20:00:00.000',
        'taken_at': null,
        'status': 'pending',
      });

      expect(log.id, 1);
      expect(log.treatmentId, 42);
      expect(log.scheduledAt, DateTime(2026, 11, 7, 20));
      expect(log.takenAt, isNull);
      expect(log.status, IntakeStatus.pending);
    });

    test('fromMap : valeurs par défaut sûres', () {
      final log = IntakeLog.fromMap({
        'treatment_id': 5,
        'scheduled_at': '2026-11-07T08:00:00.000',
      });

      expect(log.id, isNull);
      expect(log.takenAt, isNull);
      expect(log.status, IntakeStatus.pending);
    });

    test('aller-retour toMap / fromMap', () {
      final original = IntakeLog(
        id: 3,
        treatmentId: 1,
        scheduledAt: DateTime(2026, 2, 3, 7, 45),
        takenAt: DateTime(2026, 2, 3, 7, 50),
        status: IntakeStatus.taken,
      );

      final copie = IntakeLog.fromMap(original.toMap());

      expect(copie.id, original.id);
      expect(copie.treatmentId, original.treatmentId);
      expect(copie.scheduledAt, original.scheduledAt);
      expect(copie.takenAt, original.takenAt);
      expect(copie.status, original.status);
    });
  });

  group('TreatmentSummary — progression', () {
    test('aucune prise passée -> 0', () {
      final summary = TreatmentSummary(
        treatment: _treatment(),
        takenCount: 0,
        pastCount: 0,
      );

      expect(summary.progress, 0);
    });

    test('moitié des prises effectuées', () {
      final summary = TreatmentSummary(
        treatment: _treatment(),
        takenCount: 5,
        pastCount: 10,
      );

      expect(summary.progress, 0.5);
    });

    test('progression plafonnée à 1', () {
      final summary = TreatmentSummary(
        treatment: _treatment(),
        takenCount: 12,
        pastCount: 10,
      );

      expect(summary.progress, 1.0);
    });

    test('aucune prise effectuée', () {
      final summary = TreatmentSummary(
        treatment: _treatment(),
        takenCount: 0,
        pastCount: 4,
      );

      expect(summary.progress, 0.0);
    });
  });

  group('Helpers de dates français', () {
    test('fmtDate : jour et mois sur 2 chiffres', () {
      expect(fmtDate(DateTime(2026, 9, 5)), '05/09/2026');
      expect(fmtDate(DateTime(2026, 12, 31, 23, 59)), '31/12/2026');
    });

    test('fmtTime : minute sur 2 chiffres, heure non complétée', () {
      expect(fmtTime(DateTime(2026, 1, 1, 20, 0)), '20:00');
      expect(fmtTime(DateTime(2026, 1, 1, 8, 7)), '8:07');
    });

    test('fmtDateLettres : jour de la semaine + mois abrégé', () {
      expect(fmtDateLettres(DateTime(2026, 8, 12)), 'Wednesday, Aug 12');
      expect(fmtDateLettres(DateTime(2026, 11, 7)), 'Saturday, Nov 7');
    });

    test('fmtProchainePrise : pas de prochaine prise', () {
      expect(fmtProchainePrise(null, DateTime(2026, 11, 7, 9)), '—');
    });

    test('fmtProchainePrise : aujourd\'hui', () {
      final now = DateTime(2026, 11, 7, 9);
      expect(
        fmtProchainePrise(DateTime(2026, 11, 7, 20), now),
        "Today at 20:00",
      );
    });

    test('fmtProchainePrise : demain', () {
      final now = DateTime(2026, 11, 7, 9);
      expect(
        fmtProchainePrise(DateTime(2026, 11, 8, 8), now),
        'Tomorrow at 8:00',
      );
    });

    test('fmtProchainePrise : date plus lointaine', () {
      final now = DateTime(2026, 11, 7, 9);
      expect(
        fmtProchainePrise(DateTime(2026, 11, 9, 8), now),
        'Monday, Nov 9 at 8:00',
      );
    });

    test('fmtPeriode : période bornée ou chronique', () {
      expect(
        fmtPeriode(DateTime(2026, 9, 1), DateTime(2026, 9, 30)),
        '01/09/2026 – 30/09/2026',
      );
      expect(
        fmtPeriode(DateTime(2026, 9, 1), null),
        'Since 01/09/2026 · chronic',
      );
    });
  });
}
