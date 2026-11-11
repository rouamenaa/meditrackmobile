import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../models/appointment_status.dart';

const _kGreen = Color(0xFF0B6B5D);
const _kNavy = Color(0xFF0A2540);

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final bool showPatient;
  final bool canChangeStatus;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<AppointmentStatus> onStatusChanged;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.showPatient = false,
    this.canChangeStatus = false,
    required this.onTap,
    required this.onDelete,
    required this.onStatusChanged,
  });

  String _formatDate(DateTime dt) {
    const months = [
      'Jan.',
      'Feb.',
      'Mar.',
      'Apr.',
      'May',
      'Jun.',
      'Jul.',
      'Aug.',
      'Sep.',
      'Oct.',
      'Nov.',
      'Dec.',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year at $hour:$minute';
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete this appointment?'),
        content: Text(
          'Do you really want to delete the appointment with ${showPatient ? appointment.patientName ?? "this patient" : appointment.practitioner?.fullName ?? "this practitioner"}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = appointment.status;
    final isTeleconsult = appointment.isTeleconsultation;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ligne supérieure : Date / Heure & Statut
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDEFFD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isTeleconsult
                          ? Icons.videocam_rounded
                          : Icons.calendar_month_rounded,
                      color: _kGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(appointment.startDateTime),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${appointment.durationMinutes} min',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isTeleconsult
                                    ? Colors.purple.shade50
                                    : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isTeleconsult
                                    ? 'Teleconsultation'
                                    : 'In-person',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isTeleconsult
                                      ? Colors.purple.shade800
                                      : Colors.blue.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Menu statut & suppression
                  if (canChangeStatus)
                    PopupMenuButton<AppointmentStatus>(
                      icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                      tooltip: 'Change status',
                      onSelected: onStatusChanged,
                      itemBuilder: (ctx) => [
                        ...AppointmentStatus.values
                            .where((s) =>
                                s != AppointmentStatus.CANCELLED_BY_PATIENT)
                            .map(
                          (s) => PopupMenuItem(
                            value: s,
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: s.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(s.labelFr),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const Divider(height: 20),

              // Motif du rendez-vous
              Text(
                appointment.reason,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _kNavy,
                ),
              ),
              const SizedBox(height: 6),

              // Affiche l'autre participant selon le rôle connecté.
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      showPatient
                          ? appointment.patientName ?? 'Patient'
                          : appointment.practitioner != null
                          ? '${appointment.practitioner!.fullName} (${appointment.practitioner!.specialty})'
                          : 'Practitioner #${appointment.practitionerId}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              // Lieu / Structure ou lien visio
              if (appointment.facility != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${appointment.facility!.name} • ${appointment.facility!.address}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              if (isTeleconsult &&
                  appointment.videoUrl != null &&
                  appointment.videoUrl!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.link_rounded, size: 16, color: _kGreen),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        appointment.videoUrl!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _kGreen,
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Ligne inférieure : Badge Statut & Bouton Supprimer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: status.backgroundColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: status.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          status.labelFr,
                          style: TextStyle(
                            color: status.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Color(0xFFD32F2F),
                    ),
                    tooltip: 'Delete',
                    onPressed: () => _showDeleteDialog(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
