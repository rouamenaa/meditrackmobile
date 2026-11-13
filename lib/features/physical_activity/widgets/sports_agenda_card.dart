import 'package:flutter/material.dart';
import '../../auth/services/session.dart';
import '../models/physical_activity.dart';
import '../services/activity_service.dart';

/// Carte « Mon agenda sportif » intégrée sur la page d'accueil de MediTrack.
///
/// Réactive : écoute immédiatement [ActivityService.changeNotifier] pour
/// mettre à jour le compteur du mois en cours dès qu'une séance est ajoutée,
/// modifiée ou supprimée dans SQLite.
class SportsAgendaCard extends StatefulWidget {
  final String? userId;
  final VoidCallback onOpen;

  const SportsAgendaCard({
    super.key,
    this.userId,
    required this.onOpen,
  });

  @override
  State<SportsAgendaCard> createState() => _SportsAgendaCardState();
}

class _SportsAgendaCardState extends State<SportsAgendaCard> {
  final ActivityService _activityService = ActivityService();

  List<PhysicalActivity> _activities = [];
  bool _loading = true;

  String? get _effectiveUserId =>
      widget.userId ?? Session.instance.user?.id;

  @override
  void initState() {
    super.initState();
    // Écoute réactive des mutations SQLite (ajout, modification, suppression)
    ActivityService.changeNotifier.addListener(_onActivitiesChanged);
    _load();
  }

  @override
  void didUpdateWidget(SportsAgendaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _load();
    }
  }

  @override
  void dispose() {
    ActivityService.changeNotifier.removeListener(_onActivitiesChanged);
    super.dispose();
  }

  void _onActivitiesChanged() {
    if (mounted) {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final list = await _activityService.getAll(userId: _effectiveUserId);
      if (!mounted) return;
      setState(() {
        _activities = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _handleOpen() async {
    widget.onOpen();
    if (mounted) {
      await _load();
    }
  }

  String _formatDateShort(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');

    if (target == today) {
      return "Today at $hour:$minute";
    }
    if (target == today.add(const Duration(days: 1))) {
      return "Tomorrow at $hour:$minute";
    }
    return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} at $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    const kPrimary = Color(0xFF0B6B5D);
    const kTextPrimary = Color(0xFF0A2540);
    const kTextSecondary = Color(0xFF64748B);

    final now = DateTime.now();
    // Séances du mois actuel uniquement (filtrage strict sur l'année et le mois locaux)
    final thisMonthCount = _activities.where((a) {
      final d = a.activityDate.toLocal();
      return d.year == now.year && d.month == now.month;
    }).length;

    // Prochaine séance à venir
    final upcomingActivities = _activities
        .where((a) => a.activityDate.isAfter(now))
        .toList()
      ..sort((a, b) => a.activityDate.compareTo(b.activityDate));

    final nextActivity =
        upcomingActivities.isNotEmpty ? upcomingActivities.first : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleOpen,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête : Badge + Titre + Pillule du mois
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        size: 20,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'WORKOUT AGENDA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: kPrimary,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Activity Schedule',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _loading
                            ? '...'
                            : '$thisMonthCount this month',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: kPrimary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Contenu central : prochaine séance ou incitation
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: nextActivity != null
                      ? Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: kPrimary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(nextActivity.icon,
                                  size: 17, color: kPrimary),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        nextActivity.typeLabel,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                          color: kTextPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '(${nextActivity.durationMinutes} min)',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: kTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatDateShort(nextActivity.activityDate),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: kPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.alarm_on_rounded,
                                      size: 12, color: Color(0xFF047857)),
                                  SizedBox(width: 3),
                                  Text(
                                    '-5 min',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF047857),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : const Row(
                          children: [
                            Icon(
                              Icons.event_note_rounded,
                              size: 18,
                              color: kTextSecondary,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'View your past workouts and schedule upcoming activities.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: kTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 12),

                // Bouton d'action
                SizedBox(
                  height: 42,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleOpen,
                    icon: const Icon(Icons.calendar_month_rounded, size: 17),
                    label: const Text(
                      'Open workout agenda',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
