import 'package:flutter/material.dart';
import '../../auth/services/session.dart';
import '../models/activity_reminder_settings.dart';
import '../models/physical_activity.dart';
import '../services/activity_reminder_service.dart';
import '../services/activity_service.dart';

class ActivityReminderScreen extends StatefulWidget {
  final String? userId;

  const ActivityReminderScreen({super.key, this.userId});

  @override
  State<ActivityReminderScreen> createState() => _ActivityReminderScreenState();
}

class _ActivityReminderScreenState extends State<ActivityReminderScreen> {
  final _reminderService = ActivityReminderService();
  final _activityService = ActivityService();

  bool _loading = true;
  bool _isSaving = false;

  late ActivityReminderSettings _settings;
  List<PhysicalActivity> _upcomingActivities = [];

  String? get _effectiveUserId =>
      widget.userId ?? Session.instance.user?.id;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final settings = await _reminderService.loadSettings();
    final allActivities = await _activityService.getAll(userId: _effectiveUserId);
    final now = DateTime.now();

    // Filtre uniquement les séances dont l'heure se situe dans le futur
    final upcoming = allActivities
        .where((a) => a.activityDate.isAfter(now))
        .toList()
      ..sort((a, b) => a.activityDate.compareTo(b.activityDate));

    if (!mounted) return;
    setState(() {
      _settings = settings;
      _upcomingActivities = upcoming;
      _loading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    await _reminderService.saveSettings(_settings);

    // Re-synchronise les rappels pour toutes les séances futures selon le nouvel état
    await _reminderService.syncUpcomingReminders(_upcomingActivities);

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reminder preferences updated successfully'),
        backgroundColor: Color(0xFF0B6B5D),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop(true);
  }

  Future<void> _testNotification() async {
    await _reminderService.showInstantTestNotification();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Test notification sent (5 min reminder)!',
        ),
        backgroundColor: Color(0xFF0B6B5D),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$month/$day/$year at $hour:$minute';
  }

  String _formatTimeOnly(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    const kPrimaryGreen = Color(0xFF0B6B5D);
    const kNavy = Color(0xFF0A2540);
    const kBackground = Color(0xFFF8F7FF);

    if (_loading) {
      return const Scaffold(
        backgroundColor: kBackground,
        body: Center(
          child: CircularProgressIndicator(color: kPrimaryGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text(
          'Smart Reminders',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: kNavy,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Bannière d'information sur la suppression des anciens rappels fixes
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade800, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Legacy fixed daily reminders have been removed. Notifications are now automatically triggered 5 minutes before each scheduled session.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.blue.shade900,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Carte Activation des rappels de séances (5 min avant)
            _buildCard(
              title: 'Workout reminders (-5 minutes)',
              icon: Icons.timer_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Enable automatic notifications',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: kNavy,
                      ),
                    ),
                    subtitle: const Text(
                      'Receive a notification 5 minutes before each scheduled session',
                      style: TextStyle(fontSize: 12.5),
                    ),
                    value: _settings.enabled,
                    activeThumbColor: kPrimaryGreen,
                    onChanged: (val) {
                      setState(() {
                        _settings = _settings.copyWith(enabled: val);
                      });
                    },
                  ),
                  const Divider(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 16, color: kPrimaryGreen),
                      const SizedBox(width: 8),
                      Text(
                        'Notice before session: ${_settings.leadTimeMinutes} minutes',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kNavy,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Carte des prochaines séances programmées et leurs rappels
            _buildCard(
              title: 'Upcoming workouts (${_upcomingActivities.length})',
              icon: Icons.event_available_rounded,
              child: _upcomingActivities.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.event_busy_rounded,
                              size: 28, color: Colors.grey.shade400),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No upcoming workouts scheduled. Add a workout (e.g. walk tomorrow at 10:00) to receive an automatic reminder 5 minutes before.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: _upcomingActivities.map((activity) {
                        final reminderTime =
                            _settings.calculateReminderTime(activity.activityDate);
                        final isReminderFuture =
                            _settings.isReminderInFuture(activity.activityDate);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: kPrimaryGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  activity.icon,
                                  color: kPrimaryGreen,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${activity.typeLabel} (${activity.durationMinutes} min)',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: kNavy,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatDateTime(activity.activityDate),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          isReminderFuture && _settings.enabled
                                              ? Icons.notifications_active_rounded
                                              : Icons.notifications_off_outlined,
                                          size: 13,
                                          color: isReminderFuture && _settings.enabled
                                              ? kPrimaryGreen
                                              : Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isReminderFuture && _settings.enabled
                                              ? 'Reminder scheduled at ${_formatTimeOnly(reminderTime)}'
                                              : (isReminderFuture
                                                  ? 'Reminders disabled'
                                                  : 'Reminder passed'),
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: isReminderFuture && _settings.enabled
                                              ? kPrimaryGreen
                                              : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 16),

            // 4. Bouton Tester une notification
            OutlinedButton.icon(
              onPressed: _testNotification,
              icon: const Icon(Icons.notification_important_outlined,
                  color: kPrimaryGreen),
              label: const Text(
                'Test notification (-5 min)',
                style: TextStyle(
                  color: kPrimaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: kPrimaryGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 5. Bouton Enregistrer les préférences
            ElevatedButton(
              onPressed: _isSaving ? null : _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 1,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save preferences',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    const kPrimaryGreen = Color(0xFF0B6B5D);
    const kNavy = Color(0xFF0A2540);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: kPrimaryGreen, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: kNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
