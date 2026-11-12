import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/appointment.dart';
import '../models/appointment_status.dart';
import '../services/routing_service.dart';

const _kGreen = Color(0xFF0B6B5D);
const _kNavy = Color(0xFF0A2540);

class AppointmentCard extends StatefulWidget {
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

  @override
  State<AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<AppointmentCard> {
  RouteInfo? _routeInfo;
  bool _isLoadingRoute = false;

  Appointment get appointment => widget.appointment;

  @override
  void initState() {
    super.initState();
    if (!appointment.isTeleconsultation &&
        appointment.facility?.latitude != null &&
        appointment.facility?.longitude != null) {
      _calculateRoute();
    }
  }

  Future<void> _calculateRoute() async {
    final facility = appointment.facility;
    if (facility == null || facility.latitude == null || facility.longitude == null) {
      return;
    }

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _isLoadingRoute = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _isLoadingRoute = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _isLoadingRoute = false);
        return;
      }

      Position? position = await Geolocator.getLastKnownPosition();
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 4),
          ),
        );
      } catch (_) {}

      final userLat = position?.latitude ?? 36.8065;
      final userLng = position?.longitude ?? 10.1815;

      final info = await RoutingService.instance.getDrivingRoute(
        startLat: userLat,
        startLng: userLng,
        destLat: facility.latitude!,
        destLng: facility.longitude!,
      );

      if (mounted) {
        setState(() {
          _routeInfo = info;
          _isLoadingRoute = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingRoute = false);
      }
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan.', 'Fév.', 'Mars', 'Avr.', 'Mai', 'Juin',
      'Juil.', 'Août', 'Sept.', 'Oct.', 'Nov.', 'Déc.'
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year à $hour:$minute';
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ce rendez-vous ?'),
        content: Text(
          'Voulez-vous vraiment supprimer le rendez-vous avec ${widget.showPatient ? appointment.patientName ?? "ce patient" : appointment.practitioner?.fullName ?? "ce praticien"} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onDelete();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = appointment.status;
    final isTeleconsult = appointment.isTeleconsultation;
    final facility = appointment.facility;
    final hasCoords = facility?.latitude != null && facility?.longitude != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                                isTeleconsult ? 'Téléconsultation' : 'Présentiel',
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
                  PopupMenuButton<AppointmentStatus>(
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                    tooltip: 'Changer le statut',
                    onSelected: widget.onStatusChanged,
                    itemBuilder: (ctx) => [
                      ...AppointmentStatus.values.map(
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
              Text(
                appointment.reason,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _kNavy,
                ),
              ),
              const SizedBox(height: 6),
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
                      widget.showPatient
                          ? appointment.patientName ?? 'Patient'
                          : appointment.practitioner != null
                          ? '${appointment.practitioner!.fullName} (${appointment.practitioner!.specialty})'
                          : 'Praticien #${appointment.practitionerId}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (facility != null) ...[
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
                        '${facility.name} • ${facility.address}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
              if (!isTeleconsult && hasCoords) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kGreen.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _kGreen.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.directions_car_rounded, size: 18, color: _kGreen),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _isLoadingRoute
                            ? Row(
                                children: const [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: _kGreen),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Calcul de l\'itinéraire...',
                                    style: TextStyle(fontSize: 12, color: _kGreen),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _routeInfo != null
                                        ? 'À ${_routeInfo!.formattedDistance} (~${_routeInfo!.formattedDuration})'
                                        : 'Itinéraire disponible',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _kNavy,
                                    ),
                                  ),
                                  Text(
                                    facility?.name ?? 'Lieu de consultation',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: _kGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.navigation_outlined, size: 16),
                        label: const Text('Y aller', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () {
                          RoutingService.instance.openMapNavigation(
                            destLat: facility!.latitude!,
                            destLng: facility.longitude!,
                            destinationLabel: facility.name,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
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
                    tooltip: 'Supprimer',
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
