import 'package:flutter_test/flutter_test.dart';
import 'package:meditrackmobile/features/appointments/models/appointment.dart';
import 'package:meditrackmobile/features/appointments/models/appointment_status.dart';
import 'package:meditrackmobile/features/appointments/models/health_facility.dart';
import 'package:meditrackmobile/features/appointments/models/practitioner.dart';

void main() {
  group('AppointmentStatus Enum Tests', () {
    test('French labels should match expected values', () {
      expect(AppointmentStatus.SCHEDULED.labelFr, 'Programmé');
      expect(AppointmentStatus.CONFIRMED.labelFr, 'Confirmé');
      expect(AppointmentStatus.RESCHEDULED.labelFr, 'Reporté');
      expect(AppointmentStatus.CANCELLED_BY_PATIENT.labelFr, 'Annulé par patient');
      expect(AppointmentStatus.CANCELLED_BY_PRACTITIONER.labelFr, 'Annulé par praticien');
      expect(AppointmentStatus.COMPLETED.labelFr, 'Terminé');
      expect(AppointmentStatus.MISSED.labelFr, 'Manqué');
    });

    test('fromString should handle casing and fallback safely', () {
      expect(AppointmentStatus.fromString('confirmed'), AppointmentStatus.CONFIRMED);
      expect(AppointmentStatus.fromString('SCHEDULED'), AppointmentStatus.SCHEDULED);
      expect(AppointmentStatus.fromString('UNKNOWN_STATUS'), AppointmentStatus.SCHEDULED);
      expect(AppointmentStatus.fromString(null), AppointmentStatus.SCHEDULED);
    });
  });

  group('Practitioner Model Tests', () {
    test('Serialization toMap and fromMap', () {
      final practitioner = Practitioner(
        id: 1,
        lastName: 'Ben Salah',
        firstName: 'Sami',
        title: 'Dr',
        specialty: 'Cardiologie',
        rppsAdeli: '10003456789',
        phone: '+216 71 234 567',
        email: 'sami@meditrack.tn',
      );

      final map = practitioner.toMap();
      expect(map['id'], 1);
      expect(map['last_name'], 'Ben Salah');
      expect(map['first_name'], 'Sami');
      expect(map['specialty'], 'Cardiologie');

      final reconstructed = Practitioner.fromMap(map);
      expect(reconstructed.id, 1);
      expect(reconstructed.fullName, 'Dr Sami Ben Salah');
      expect(reconstructed.specialty, 'Cardiologie');
    });

    test('copyWith updates fields correctly', () {
      final practitioner = Practitioner(
        id: 1,
        lastName: 'Mansouri',
        firstName: 'Leila',
        specialty: 'Généraliste',
      );

      final updated = practitioner.copyWith(specialty: 'Pédiatrie');
      expect(updated.specialty, 'Pédiatrie');
      expect(updated.lastName, 'Mansouri');
      expect(updated.firstName, 'Leila');
    });
  });

  group('HealthFacility Model Tests', () {
    test('Serialization and fullAddress', () {
      final facility = HealthFacility(
        id: 1,
        name: 'Cabinet Médical El Amen',
        type: 'cabinet',
        address: '12 Avenue Habib Bourguiba',
        buildingFloor: '2ème étage',
        latitude: 36.8008,
        longitude: 10.1800,
      );

      final map = facility.toMap();
      expect(map['name'], 'Cabinet Médical El Amen');
      expect(map['building_floor'], '2ème étage');

      final reconstructed = HealthFacility.fromMap(map);
      expect(reconstructed.fullAddress, '12 Avenue Habib Bourguiba (2ème étage)');
      expect(reconstructed.latitude, 36.8008);
    });
  });

  group('Appointment Model Tests', () {
    test('Serialization toMap and fromMap with joins', () {
      final practitioner = Practitioner(
        id: 2,
        lastName: 'Trabelsi',
        firstName: 'Mohamed',
        title: 'Pr',
        specialty: 'Pneumologie',
      );

      final facility = HealthFacility(
        id: 3,
        name: 'Hôpital Militaire',
        type: 'hôpital',
        address: 'Montfleury',
      );

      final start = DateTime(2026, 11, 15, 14, 30);
      final appointment = Appointment(
        id: 10,
        practitionerId: 2,
        facilityId: 3,
        startDateTime: start,
        durationMinutes: 45,
        reason: 'Contrôle respiratoire',
        notes: 'Apporter spirométrie',
        modality: 'presentiel',
        status: AppointmentStatus.CONFIRMED,
        practitioner: practitioner,
        facility: facility,
      );

      final map = appointment.toMap();
      expect(map['id'], 10);
      expect(map['practitioner_id'], 2);
      expect(map['facility_id'], 3);
      expect(map['reason'], 'Contrôle respiratoire');
      expect(map['duration_minutes'], 45);
      expect(map['status'], 'CONFIRMED');

      final reconstructed = Appointment.fromMap(
        map,
        practitioner: practitioner,
        facility: facility,
      );

      expect(reconstructed.id, 10);
      expect(reconstructed.reason, 'Contrôle respiratoire');
      expect(reconstructed.practitioner?.fullName, 'Pr Mohamed Trabelsi');
      expect(reconstructed.facility?.name, 'Hôpital Militaire');
      expect(reconstructed.endDateTime, DateTime(2026, 11, 15, 15, 15));
      expect(reconstructed.isTeleconsultation, false);
    });

    test('Teleconsultation detection and videoUrl', () {
      final appointment = Appointment(
        practitionerId: 1,
        startDateTime: DateTime.now().add(const Duration(days: 2)),
        reason: 'Téléconsultation test',
        modality: 'teleconsultation',
        videoUrl: 'https://meet.jit.si/meditrack-123',
      );

      expect(appointment.isTeleconsultation, true);
      expect(appointment.videoUrl, 'https://meet.jit.si/meditrack-123');
    });
  });
}
