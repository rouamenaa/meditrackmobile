// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

enum AppointmentStatus {
  SCHEDULED,
  CONFIRMED,
  RESCHEDULED,
  CANCELLED_BY_PATIENT,
  CANCELLED_BY_PRACTITIONER,
  COMPLETED,
  MISSED;

  String get labelFr {
    switch (this) {
      case AppointmentStatus.SCHEDULED:
        return 'Scheduled';
      case AppointmentStatus.CONFIRMED:
        return 'Confirmed';
      case AppointmentStatus.RESCHEDULED:
        return 'Rescheduled';
      case AppointmentStatus.CANCELLED_BY_PATIENT:
        return 'Cancelled by patient';
      case AppointmentStatus.CANCELLED_BY_PRACTITIONER:
        return 'Cancelled by practitioner';
      case AppointmentStatus.COMPLETED:
        return 'Completed';
      case AppointmentStatus.MISSED:
        return 'Missed';
    }
  }

  Color get color {
    switch (this) {
      case AppointmentStatus.SCHEDULED:
        return const Color(0xFF1976D2); // Bleu
      case AppointmentStatus.CONFIRMED:
        return const Color(0xFF0B6B5D); // Vert MediTrack
      case AppointmentStatus.RESCHEDULED:
        return const Color(0xFFF57C00); // Orange
      case AppointmentStatus.CANCELLED_BY_PATIENT:
      case AppointmentStatus.CANCELLED_BY_PRACTITIONER:
        return const Color(0xFFD32F2F); // Rouge
      case AppointmentStatus.COMPLETED:
        return const Color(0xFF388E3C); // Vert foncé
      case AppointmentStatus.MISSED:
        return const Color(0xFF757575); // Gris
    }
  }

  Color get backgroundColor {
    return color.withValues(alpha: 0.12);
  }

  static AppointmentStatus fromString(String? value) {
    if (value == null) return AppointmentStatus.SCHEDULED;
    return AppointmentStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => AppointmentStatus.SCHEDULED,
    );
  }
}
