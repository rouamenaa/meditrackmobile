import 'appointment_status.dart';
import 'health_facility.dart';
import 'practitioner.dart';

class Appointment {
  final int? id;
  final String? remoteId;
  final int practitionerId;
  final String? doctorUserId;
  final int? facilityId;
  final String? facilityName;
  final String? facilityAddress;
  final String? patientId; // identifiant Mongo de l'utilisateur patient
  final String? patientName; // nom affiché du patient
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
    this.remoteId,
    required this.practitionerId,
    this.doctorUserId,
    this.facilityId,
    this.facilityName,
    this.facilityAddress,
    this.patientId,
    this.patientName,
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
    'remote_id': remoteId,
    'practitioner_id': practitionerId,
    'doctor_user_id': doctorUserId,
    'facility_id': facilityId,
    'facility_name': facilityName,
    'facility_address': facilityAddress,
    'patient_id': patientId,
    'patient_name': patientName,
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
      remoteId: map['remote_id'] as String?,
      practitionerId: map['practitioner_id'] as int,
      doctorUserId: map['doctor_user_id'] as String?,
      facilityId: map['facility_id'] as int?,
      facilityName: map['facility_name'] as String?,
      facilityAddress: map['facility_address'] as String?,
      patientId: map['patient_id'] as String?,
      patientName: map['patient_name'] as String?,
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
    String? remoteId,
    int? practitionerId,
    String? doctorUserId,
    int? facilityId,
    String? facilityName,
    String? facilityAddress,
    String? patientId,
    String? patientName,
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
      remoteId: remoteId ?? this.remoteId,
      practitionerId: practitionerId ?? this.practitionerId,
      doctorUserId: doctorUserId ?? this.doctorUserId,
      facilityId: facilityId ?? this.facilityId,
      facilityName: facilityName ?? this.facilityName,
      facilityAddress: facilityAddress ?? this.facilityAddress,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
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
