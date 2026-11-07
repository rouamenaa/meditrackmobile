import 'package:flutter/material.dart';
import '../../../database/database_helper.dart';
import '../models/appointment.dart';
import '../models/appointment_status.dart';
import '../models/health_facility.dart';
import '../models/practitioner.dart';

class AppointmentProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Appointment> _appointments = [];
  List<Practitioner> _practitioners = [];
  List<HealthFacility> _facilities = [];
  bool _isLoading = false;
  String? _errorMessage;

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
  // CHARGEMENT GLOBAL
  // ===========================================================================

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _dbHelper.getAllAppointments(),
        _dbHelper.getAllPractitioners(),
        _dbHelper.getAllHealthFacilities(),
      ]);

      _appointments = results[0] as List<Appointment>;
      _practitioners = results[1] as List<Practitioner>;
      _facilities = results[2] as List<HealthFacility>;
    } catch (e) {
      _errorMessage = 'Erreur de chargement: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // OPÉRATIONS SUR LES RENDEZ-VOUS
  // ===========================================================================

  Future<bool> addAppointment(Appointment appointment) async {
    try {
      await _dbHelper.insertAppointment(appointment);
      await loadAll();
      return true;
    } catch (e) {
      _errorMessage = "Impossible d'ajouter le rendez-vous: $e";
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAppointment(Appointment appointment) async {
    try {
      await _dbHelper.updateAppointment(appointment);
      await loadAll();
      return true;
    } catch (e) {
      _errorMessage = "Impossible de modifier le rendez-vous: $e";
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAppointment(int id) async {
    try {
      await _dbHelper.deleteAppointment(id);
      await loadAll();
      return true;
    } catch (e) {
      _errorMessage = "Impossible de supprimer le rendez-vous: $e";
      notifyListeners();
      return false;
    }
  }

  Future<bool> changeStatus(int id, AppointmentStatus status) async {
    try {
      await _dbHelper.updateAppointmentStatus(id, status);
      await loadAll();
      return true;
    } catch (e) {
      _errorMessage = "Impossible de mettre à jour le statut: $e";
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
      _errorMessage = "Impossible d'ajouter le praticien: $e";
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
      _errorMessage = "Impossible d'ajouter la structure: $e";
      notifyListeners();
      return null;
    }
  }
}
