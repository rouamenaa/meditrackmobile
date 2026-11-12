import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config.dart';
import '../../auth/services/session.dart';
import '../models/appointment.dart';
import '../models/appointment_status.dart';

class AppointmentApiService {
  AppointmentApiService._();
  static final AppointmentApiService instance = AppointmentApiService._();

  String get _baseUrl => '$kBaseUrl/appointments';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (Session.instance.token != null)
          'Authorization': 'Bearer ${Session.instance.token}',
      };

  /// Récupère tous les rendez-vous de l'utilisateur depuis MongoDB
  Future<List<Appointment>> fetchAppointments() async {
    final response = await http
        .get(Uri.parse(_baseUrl), headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((json) {
        return Appointment(
          id: null, // ID local SQLite géré localement
          practitionerId: (json['practitioner']?['id'] as num?)?.toInt() ?? 1,
          facilityId: (json['facility']?['id'] as num?)?.toInt(),
          startDateTime: DateTime.parse(json['startDateTime']),
          durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 30,
          reason: json['reason'] ?? '',
          notes: json['notes'],
          modality: json['modality'] ?? 'presentiel',
          videoUrl: json['videoUrl'],
          status: AppointmentStatus.fromString(json['status']),
        );
      }).toList();
    }
    throw Exception('Erreur de chargement MongoDB: ${response.statusCode}');
  }

  /// Sauvegarde un rendez-vous dans MongoDB
  Future<bool> createAppointment(Appointment appointment) async {
    try {
      print('[AppointmentApiService] Envoi vers $_baseUrl...');
      final body = jsonEncode({
        'practitioner': appointment.practitioner?.toMap() ?? {
          'id': appointment.practitionerId,
          'lastName': 'Praticien',
          'firstName': '#${appointment.practitionerId}',
          'specialty': 'Général',
        },
        if (appointment.facility != null) ...{
          'facility': appointment.facility!.toMap(),
          'facility_name': appointment.facility!.name,
          'facility_address': appointment.facility!.fullAddress,
        },
        if (appointment.facilityName != null && appointment.facility == null)
          'facility_name': appointment.facilityName,
        if (appointment.facilityAddress != null && appointment.facility == null)
          'facility_address': appointment.facilityAddress,
        'startDateTime': appointment.startDateTime.toIso8601String(),
        'durationMinutes': appointment.durationMinutes,
        'reason': appointment.reason,
        'notes': appointment.notes,
        'modality': appointment.modality,
        'videoUrl': appointment.videoUrl,
        'status': appointment.status.name,
      });

      final response = await http
          .post(Uri.parse(_baseUrl), headers: _headers, body: body)
          .timeout(const Duration(seconds: 8));

      print('[AppointmentApiService] Réponse backend: ${response.statusCode} - ${response.body}');
      return response.statusCode == 201;
    } catch (e) {
      print('[AppointmentApiService] Erreur HTTP: $e');
      return false;
    }
  }

  /// Met à jour le statut d'un rendez-vous sur le serveur
  Future<bool> updateStatus(String remoteId, AppointmentStatus status) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$_baseUrl/$remoteId/status'),
            headers: _headers,
            body: jsonEncode({'status': status.name}),
          )
          .timeout(const Duration(seconds: 8));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

