import 'package:flutter/material.dart';

import '../../../database/database_helper.dart';
import '../../auth/models/user.dart';
import '../../auth/services/api_service.dart';
import '../models/appointment.dart';
import '../models/appointment_status.dart';
import '../models/health_facility.dart';
import '../models/practitioner.dart';
import 'appointment_api_service.dart';
import 'appointment_service.dart';

class AppointmentProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AppointmentService _appointmentService = AppointmentService();
  final AppointmentApiService _apiService = AppointmentApiService.instance;

  List<Appointment> _appointments = [];
  List<Practitioner> _practitioners = [];
  List<HealthFacility> _facilities = [];
  bool _isLoading = false;
  String? _errorMessage;
  Future<void> _loadQueue = Future<void>.value();

  List<Appointment> get appointments => List.unmodifiable(_appointments);
  List<Practitioner> get practitioners => List.unmodifiable(_practitioners);
  List<HealthFacility> get facilities => List.unmodifiable(_facilities);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Rendez-vous à venir (non passés et non annulés)
  List<Appointment> get upcomingAppointments {
    final now = DateTime.now();
    return _appointments.where((a) {
      final isCancelled =
          a.status == AppointmentStatus.CANCELLED_BY_PATIENT ||
          a.status == AppointmentStatus.CANCELLED_BY_PRACTITIONER;
      return a.startDateTime.isAfter(now) && !isCancelled;
    }).toList();
  }

  /// Rendez-vous passés ou terminés ou annulés
  List<Appointment> get pastAppointments {
    final now = DateTime.now();
    return _appointments.where((a) {
      final isCancelled =
          a.status == AppointmentStatus.CANCELLED_BY_PATIENT ||
          a.status == AppointmentStatus.CANCELLED_BY_PRACTITIONER;
      return a.startDateTime.isBefore(now) ||
          a.status == AppointmentStatus.COMPLETED ||
          isCancelled;
    }).toList();
  }

  // ===========================================================================
  // FILTRAGE PAR RÔLE
  // ===========================================================================

  /// Rendez-vous du patient connecté (ceux qu'il a lui-même réservés).
  List<Appointment> appointmentsForPatient(User user) {
    final id = user.id;
    if (id == null) return const [];
    return _appointments.where((a) => a.patientId == id).toList();
  }

  /// Rendez-vous que le médecin connecté doit voir.
  List<Appointment> appointmentsForDoctor(User user) {
    final name = _normalize(user.fullName);
    return _appointments.where((a) {
      if (a.doctorUserId != null) return a.doctorUserId == user.id;
      if (a.practitioner?.remoteUserId != null) {
        return a.practitioner!.remoteUserId == user.id;
      }
      final practitioner = a.practitioner;
      return practitioner != null &&
          name.isNotEmpty &&
          _normalize('${practitioner.firstName} ${practitioner.lastName}') ==
              name;
    }).toList();
  }

  // ===========================================================================
  // CHARGEMENT GLOBAL
  // ===========================================================================

  Future<void> loadAll({User? user}) {
    final next = _loadQueue.then((_) => _performLoad(user: user));
    _loadQueue = next.then<void>((_) {}, onError: (_) {});
    return next;
  }

  Future<void> _performLoad({User? user}) async {
    _isLoading = true;
    _errorMessage = null;
    if (user != null) {
      _appointments = const [];
      _practitioners = const [];
    }
    notifyListeners();

    try {
      final results = await Future.wait([
        _dbHelper.getAllAppointments(),
        _dbHelper.getAllPractitioners(),
        _dbHelper.getAllHealthFacilities(),
      ]);

      _facilities = results[2] as List<HealthFacility>;

      if (user == null) {
        _appointments = results[0] as List<Appointment>;
        _practitioners = results[1] as List<Practitioner>;
      } else {
        try {
          if (user.isPatient) {
            final doctors = await _appointmentService.getDoctors();
            _practitioners = await Future.wait(doctors.map(_syncDoctor));
          } else {
            _practitioners = const [];
          }

          final remoteAppointments = await _appointmentService
              .getAppointments();
          _appointments = [];
          for (final appointment in remoteAppointments) {
            _appointments.add(await _appointmentFromApi(appointment));
          }
        } on ApiException catch (e) {
          _appointments = const [];
          _errorMessage = e.message;
        }
      }
    } catch (e) {
      _errorMessage = 'Loading error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Practitioner> _syncDoctor(Map<String, dynamic> doctor) {
    return _dbHelper.upsertDoctorPractitioner(_practitionerFromApi(doctor));
  }

  Practitioner _practitionerFromApi(Map<String, dynamic> doctor) {
    return Practitioner(
      remoteUserId: doctor['id']?.toString(),
      firstName: (doctor['prenom'] ?? '').toString(),
      lastName: (doctor['nom'] ?? '').toString(),
      specialty: (doctor['specialite'] ?? 'General Medicine').toString(),
      rppsAdeli: doctor['rpps_adeli']?.toString(),
      phone: doctor['telephone']?.toString(),
      email: doctor['email']?.toString(),
    );
  }

  Future<Appointment> _appointmentFromApi(Map<String, dynamic> data) async {
    final doctorData = data['doctor'];
    if (doctorData is! Map) {
      throw const FormatException('The appointment has no doctor details');
    }
    final doctor = _practitionerFromApi(Map<String, dynamic>.from(doctorData));
    final practitioner = await _dbHelper.upsertDoctorPractitioner(doctor);
    final facilityName = data['facility_name']?.toString();
    final facilityAddress = data['facility_address']?.toString();
    final facility = facilityName == null || facilityName.isEmpty
        ? null
        : HealthFacility(
            name: facilityName,
            type: 'Medical Office',
            address: facilityAddress ?? '',
          );

    return Appointment(
      remoteId: data['id']?.toString(),
      practitionerId: practitioner.id!,
      doctorUserId:
          data['doctor_user_id']?.toString() ?? practitioner.remoteUserId,
      patientId: data['patient_id']?.toString(),
      patientName: data['patient_name']?.toString(),
      startDateTime: DateTime.parse(data['start_date_time'].toString())
          .toLocal(),
      durationMinutes: (data['duration_minutes'] as num?)?.toInt() ?? 30,
      reason: data['reason']?.toString() ?? '',
      notes: data['notes']?.toString(),
      modality: data['modality']?.toString() ?? 'presentiel',
      videoUrl: data['video_url']?.toString(),
      status: AppointmentStatus.fromString(data['status']?.toString()),
      practitioner: practitioner,
      facility: facility,
      facilityName: facilityName,
      facilityAddress: facilityAddress,
    );
  }

  // ===========================================================================
  // OPÉRATIONS SUR LES RENDEZ-VOUS
  // ===========================================================================

  Future<bool> addAppointment(
    Appointment appointment, {
    User? user,
  }) async {
    try {
      // 1. Sauvegarde locale dans SQLite
      await _dbHelper.insertAppointment(appointment);

      // 2. Synchronisation en arrière-plan avec MongoDB (via Node.js)
      _apiService.createAppointment(appointment);

      await loadAll(user: user);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = "Unable to add the appointment: $e";
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAppointment(
    Appointment appointment, {
    User? user,
  }) async {
    try {
      final remoteId = appointment.remoteId;
      if (remoteId != null) {
        final doctorId =
            appointment.doctorUserId ??
            _doctorIdForPractitioner(appointment.practitionerId);
        if (doctorId != null) {
          await _appointmentService.updateAppointment(
            remoteId,
            _appointmentPayload(appointment, doctorId),
          );
        }
      } else if (appointment.id != null) {
        await _dbHelper.updateAppointment(appointment);
      }
      await loadAll(user: user);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = "Unable to update the appointment: $e";
      notifyListeners();
      return false;
    }
  }

  Map<String, dynamic> _appointmentPayload(
    Appointment appointment,
    String doctorId,
  ) {
    final facility = _facilityForId(appointment.facilityId);
    return {
      'doctor_user_id': doctorId,
      'start_date_time': appointment.startDateTime.toUtc().toIso8601String(),
      'duration_minutes': appointment.durationMinutes,
      'reason': appointment.reason,
      'notes': appointment.notes ?? '',
      'modality': appointment.modality,
      'video_url': appointment.videoUrl,
      'facility_name': appointment.facilityName ?? facility?.name ?? '',
      'facility_address':
          appointment.facilityAddress ?? facility?.fullAddress ?? '',
      'status': appointment.status.name,
    };
  }

  String? _doctorIdForPractitioner(int practitionerId) {
    for (final practitioner in _practitioners) {
      if (practitioner.id == practitionerId) return practitioner.remoteUserId;
    }
    return null;
  }

  HealthFacility? _facilityForId(int? facilityId) {
    if (facilityId == null) return null;
    for (final facility in _facilities) {
      if (facility.id == facilityId) return facility;
    }
    return null;
  }

  Future<bool> deleteAppointment(
    Appointment appointment, {
    User? user,
  }) async {
    try {
      if (appointment.remoteId == null) {
        if (appointment.id != null) {
          await _dbHelper.deleteAppointment(appointment.id!);
        }
      } else {
        await _appointmentService.deleteAppointment(appointment.remoteId!);
      }
      await loadAll(user: user);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = "Unable to delete the appointment: $e";
      notifyListeners();
      return false;
    }
  }

  Future<bool> changeStatus(
    Appointment appointment,
    AppointmentStatus status, {
    User? user,
  }) async {
    try {
      if (appointment.remoteId == null) {
        if (appointment.id != null) {
          await _dbHelper.updateAppointmentStatus(appointment.id!, status);
        }
      } else {
        await _appointmentService.updateAppointment(appointment.remoteId!, {
          'status': status.name,
        });
      }
      await loadAll(user: user);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = "Unable to update the status: $e";
      notifyListeners();
      return false;
    }
  }

  // ===========================================================================
  // AJOUT DE PRATICIEN / STRUCTURE (SI BESOIN DEPUIS LE FORMULAIRE)
  // ===========================================================================

  Future<Practitioner?> addPractitioner(Practitioner practitioner) async {
    try {
      final id = await _dbHelper.insertPractitioner(practitioner);
      final created = practitioner.copyWith(id: id);
      _practitioners = await _dbHelper.getAllPractitioners();
      notifyListeners();
      return created;
    } catch (e) {
      _errorMessage = "Unable to add the practitioner: $e";
      notifyListeners();
      return null;
    }
  }

  Future<HealthFacility?> addFacility(HealthFacility facility) async {
    try {
      final id = await _dbHelper.insertHealthFacility(facility);
      final created = facility.copyWith(id: id);
      _facilities = await _dbHelper.getAllHealthFacilities();
      notifyListeners();
      return created;
    } catch (e) {
      _errorMessage = "Unable to add the facility: $e";
      notifyListeners();
      return null;
    }
  }
}

/// Minuscule + suppression des accents, pour comparer des libellés saisis.
String _normalize(String value) {
  const accents = {
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'á': 'a',
    'ã': 'a',
    'ç': 'c',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'í': 'i',
    'ô': 'o',
    'ö': 'o',
    'ó': 'o',
    'õ': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ú': 'u',
    'ÿ': 'y',
    'ñ': 'n',
  };
  final buffer = StringBuffer();
  for (final ch in value.trim().toLowerCase().split('')) {
    buffer.write(accents[ch] ?? ch);
  }
  return buffer.toString();
}
