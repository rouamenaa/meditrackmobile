import 'appointment_status.dart';
import 'health_facility.dart';
import 'practitioner.dart';

class Appointment {
  final int? id;
  final int practitionerId;
  final int? facilityId;
  final DateTime startDateTime;
  final int durationMinutes;
  final String reason; // Motif
  final String? notes;
  final String modality; // "presentiel" ou "teleconsultation"
  final String? videoUrl;
  final AppointmentStatus status;

  // Objets joints optionnels pour l'affichage dans l'interface
  final Practitioner? practitioner;
  final HealthFacility? facility;

  Appointment({
    this.id,
    required this.practitionerId,
    this.facilityId,
    required this.startDateTime,
    this.durationMinutes = 30,
    required this.reason,
    this.notes,
    this.modality = 'presentiel',
    this.videoUrl,
    this.status = AppointmentStatus.SCHEDULED,
    this.practitioner,
    this.facility,
  });

  DateTime get endDateTime =>
      startDateTime.add(Duration(minutes: durationMinutes));

  bool get isTeleconsultation =>
      modality.trim().toLowerCase() == 'teleconsultation';

  bool get isPast => startDateTime.isBefore(DateTime.now());

  Map<String, dynamic> toMap() => {
    'id': id,
    'practitioner_id': practitionerId,
    'facility_id': facilityId,
    'start_date_time': startDateTime.toIso8601String(),
    'duration_minutes': durationMinutes,
    'reason': reason,
    'notes': notes,
    'modality': modality,
    'video_url': videoUrl,
    'status': status.name,
  };

  factory Appointment.fromMap(
    Map<String, dynamic> map, {
    Practitioner? practitioner,
    HealthFacility? facility,
  }) {
    return Appointment(
      id: map['id'] as int?,
      practitionerId: map['practitioner_id'] as int,
      facilityId: map['facility_id'] as int?,
      startDateTime: DateTime.parse(map['start_date_time'] as String),
      durationMinutes: (map['duration_minutes'] as int?) ?? 30,
      reason: (map['reason'] ?? '') as String,
      notes: map['notes'] as String?,
      modality: (map['modality'] ?? 'presentiel') as String,
      videoUrl: map['video_url'] as String?,
      status: AppointmentStatus.fromString(map['status'] as String?),
      practitioner: practitioner,
      facility: facility,
    );
  }

  Appointment copyWith({
    int? id,
    int? practitionerId,
    int? facilityId,
    DateTime? startDateTime,
    int? durationMinutes,
    String? reason,
    String? notes,
    String? modality,
    String? videoUrl,
    AppointmentStatus? status,
    Practitioner? practitioner,
    HealthFacility? facility,
  }) {
    return Appointment(
      id: id ?? this.id,
      practitionerId: practitionerId ?? this.practitionerId,
      facilityId: facilityId ?? this.facilityId,
      startDateTime: startDateTime ?? this.startDateTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      modality: modality ?? this.modality,
      videoUrl: videoUrl ?? this.videoUrl,
      status: status ?? this.status,
      practitioner: practitioner ?? this.practitioner,
      facility: facility ?? this.facility,
    );
  }
}
