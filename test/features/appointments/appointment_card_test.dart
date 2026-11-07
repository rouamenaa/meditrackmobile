import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditrackmobile/features/appointments/models/appointment.dart';
import 'package:meditrackmobile/features/appointments/models/appointment_status.dart';
import 'package:meditrackmobile/features/appointments/models/health_facility.dart';
import 'package:meditrackmobile/features/appointments/models/practitioner.dart';
import 'package:meditrackmobile/features/appointments/widgets/appointment_card.dart';

/// Rendez-vous de référence utilisé par les tests d'affichage.
Appointment _appointment({
  AppointmentStatus status = AppointmentStatus.CONFIRMED,
  String modality = 'presentiel',
  String? videoUrl,
}) {
  return Appointment(
    id: 10,
    practitionerId: 2,
    facilityId: 3,
    startDateTime: DateTime(2026, 11, 15, 14, 30),
    durationMinutes: 45,
    reason: 'Contrôle respiratoire',
    notes: 'Apporter spirométrie',
    modality: modality,
    videoUrl: videoUrl,
    status: status,
    practitioner: Practitioner(
      id: 2,
      lastName: 'Trabelsi',
      firstName: 'Mohamed',
      title: 'Pr',
      specialty: 'Pneumologie',
    ),
    facility: HealthFacility(
      id: 3,
      name: 'Hôpital Militaire',
      type: 'hôpital',
      address: 'Montfleury',
    ),
  );
}

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  group('AppointmentCard', () {
    testWidgets('affiche la date, le motif, le praticien, le lieu et le statut',
        (tester) async {
      await tester.pumpWidget(_wrap(AppointmentCard(
        appointment: _appointment(),
        onTap: () {},
        onDelete: () {},
        onStatusChanged: (_) {},
      )));

      expect(find.text('15 Nov. 2026 à 14:30'), findsOneWidget);
      expect(find.text('45 min'), findsOneWidget);
      expect(find.text('Présentiel'), findsOneWidget);
      expect(find.text('Contrôle respiratoire'), findsOneWidget);
      expect(find.text('Pr Mohamed Trabelsi (Pneumologie)'), findsOneWidget);
      expect(find.text('Hôpital Militaire • Montfleury'), findsOneWidget);
      expect(find.text('Confirmé'), findsOneWidget);
    });

    testWidgets('une téléconsultation affiche le badge et le lien visio',
        (tester) async {
      await tester.pumpWidget(_wrap(AppointmentCard(
        appointment: _appointment(
          modality: 'teleconsultation',
          videoUrl: 'https://meet.jit.si/meditrack-123',
        ),
        onTap: () {},
        onDelete: () {},
        onStatusChanged: (_) {},
      )));

      expect(find.text('Téléconsultation'), findsOneWidget);
      expect(find.text('https://meet.jit.si/meditrack-123'), findsOneWidget);
      expect(find.byIcon(Icons.videocam_rounded), findsOneWidget);
    });

    testWidgets('un tap sur la carte ouvre le rendez-vous', (tester) async {
      var opened = 0;
      await tester.pumpWidget(_wrap(AppointmentCard(
        appointment: _appointment(),
        onTap: () => opened++,
        onDelete: () {},
        onStatusChanged: (_) {},
      )));

      await tester.tap(find.text('Contrôle respiratoire'));
      await tester.pump();

      expect(opened, 1);
    });

    testWidgets('la suppression demande confirmation', (tester) async {
      var deleted = 0;
      await tester.pumpWidget(_wrap(AppointmentCard(
        appointment: _appointment(),
        onTap: () {},
        onDelete: () => deleted++,
        onStatusChanged: (_) {},
      )));

      // 1. On ouvre la boîte de dialogue puis on annule : rien n'est supprimé.
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text('Supprimer le rendez-vous ?'), findsOneWidget);

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(deleted, 0);

      // 2. On confirme : le callback de suppression est appelé une seule fois.
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
      await tester.pumpAndSettle();
      expect(deleted, 1);
    });

    testWidgets('le menu permet de changer le statut', (tester) async {
      AppointmentStatus? selected;
      await tester.pumpWidget(_wrap(AppointmentCard(
        appointment: _appointment(),
        onTap: () {},
        onDelete: () {},
        onStatusChanged: (status) => selected = status,
      )));

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Terminé'));
      await tester.pumpAndSettle();

      expect(selected, AppointmentStatus.COMPLETED);
    });
  });
}
