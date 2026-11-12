import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/activity_reminder_settings.dart';
import '../models/physical_activity.dart';

/// Service de notifications intelligentes pour les séances d'activité physique.
///
/// Fonctionnement :
/// - Supprime tous les anciens rappels fixes quotidiens/hebdomadaires.
/// - Programme automatiquement un rappel 5 minutes avant chaque séance programmée dans le futur.
/// - Met à jour ou annule la notification lorsque la séance est modifiée ou supprimée.
class ActivityReminderService {
  ActivityReminderService._();
  static final ActivityReminderService instance = ActivityReminderService._();
  factory ActivityReminderService() => instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String _prefsKey = 'meditrack_activity_reminder_settings_v2';

  // Plage d'IDs pour les anciens rappels fixes (à purger)
  static const int _legacySessionBaseId = 2000;
  static const int _legacyWeeklyGoalId = 2010;

  // ID pour les tests de notification
  static const int _testNotificationId = 2099;

  // Canal Android dédié aux séances d'activité physique
  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'meditrack_activities',
      'Rappels de séances d\'activité physique',
      channelDescription:
          'Notifications automatiques envoyées 5 minutes avant chaque séance de sport planifiée',
      icon: 'ic_stat_meditrack',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(''),
    ),
  );

  /// Génère un identifiant unique et stable pour la notification d'une séance donnée
  int notificationIdForActivity(int activityId) => 30000 + (activityId % 50000);

  Future<void> _initTimezone() async {
    tzdata.initializeTimeZones();
    final name = DateTime.now().timeZoneName;
    try {
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      final off = DateTime.now().timeZoneOffset;
      final hours = -off.inMinutes ~/ 60;
      final fallbackName = 'Etc/GMT${hours.isNegative ? '' : '+'}$hours';
      try {
        tz.setLocalLocation(tz.getLocation(fallbackName));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    }
  }

  /// Initialise le plugin local de notifications et supprime automatiquement les anciens rappels fixes
  Future<void> init() async {
    if (_initialized) return;

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_meditrack'),
      ),
    );

    await _initTimezone();

    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    try {
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          'meditrack_activities',
          'Rappels de séances d\'activité physique',
          description:
              'Notifications automatiques envoyées 5 minutes avant chaque séance de sport planifiée',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
    } catch (e) {
      debugPrint('[ACTIVITY REMINDERS] Canal error: $e');
    }

    try {
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    } catch (_) {}

    _initialized = true;

    // Suppression automatique de tout ancien rappel fixe résiduel
    await cancelAllLegacyFixedReminders();
  }

  /// Supprime tous les anciens rappels fixes quotidiens et hebdomadaires
  Future<void> cancelAllLegacyFixedReminders() async {
    try {
      for (int i = 1; i <= 7; i++) {
        await _plugin.cancel(id: _legacySessionBaseId + i);
      }
      await _plugin.cancel(id: _legacyWeeklyGoalId);
    } catch (e) {
      debugPrint('[ACTIVITY REMINDERS] Erreur suppression anciens rappels fixes: $e');
    }
  }

  /// Charge les réglages persistants des rappels de séance
  Future<ActivityReminderSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return ActivityReminderSettings.fromMap(decoded);
      }
    } catch (e) {
      debugPrint('[ACTIVITY REMINDERS] Error loading settings: $e');
    }
    return const ActivityReminderSettings();
  }

  /// Sauvegarde les réglages persistants
  Future<void> saveSettings(ActivityReminderSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(settings.toMap()));
    } catch (e) {
      debugPrint('[ACTIVITY REMINDERS] Error saving settings: $e');
    }
  }

  /// Programme une notification intelligente exactement 5 minutes avant la séance
  /// Retourne `true` si le rappel a été planifié (séance dans le futur), `false` sinon.
  Future<bool> scheduleReminderForActivity(PhysicalActivity activity) async {
    if (activity.id == null) return false;
    await init();

    final settings = await loadSettings();
    if (!settings.enabled) return false;

    final reminderTime = settings.calculateReminderTime(activity.activityDate);

    // Si l'heure du rappel est déjà dépassée, on ne programme rien
    if (reminderTime.isBefore(DateTime.now())) {
      debugPrint(
        '[ACTIVITY REMINDERS] Séance passée ou trop proche (${activity.activityDate}), pas de rappel programmé.',
      );
      return false;
    }

    final notifId = notificationIdForActivity(activity.id!);

    // On annule au préalable toute alarme précédente pour cet ID
    await _plugin.cancel(id: notifId);

    final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);
    final title = '⏰ Rappel séance : ${activity.type}';
    final body =
        'Votre séance de ${activity.type.toLowerCase()} (${activity.durationMinutes} min) commence dans ${settings.leadTimeMinutes} minutes ! Préparez-vous.';

    final notifDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'meditrack_activities',
        'Rappels de séances d\'activité physique',
        channelDescription:
            'Notifications automatiques envoyées 5 minutes avant chaque séance de sport planifiée',
        icon: 'ic_stat_meditrack',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(body),
      ),
    );

    try {
      await _plugin.zonedSchedule(
        id: notifId,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notifDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'activity_${activity.id}',
      );
      debugPrint(
        '[ACTIVITY REMINDERS] Rappel programmé avec succès pour ID ${activity.id} à $reminderTime (5 min avant).',
      );
      return true;
    } catch (_) {
      try {
        await _plugin.zonedSchedule(
          id: notifId,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: notifDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'activity_${activity.id}',
        );
        return true;
      } catch (err) {
        debugPrint('[ACTIVITY REMINDERS] Échec programmation alarme: $err');
        return false;
      }
    }
  }

  /// Annule immédiatement la notification programmée pour une séance supprimée ou mise à jour
  Future<void> cancelReminderForActivity(int activityId) async {
    await init();
    final notifId = notificationIdForActivity(activityId);
    await _plugin.cancel(id: notifId);
    debugPrint('[ACTIVITY REMINDERS] Rappel annulé pour la séance ID $activityId.');
  }

  /// Synchronise les notifications pour toutes les séances futures données
  /// (utile au lancement ou lors du rechargement de la liste)
  Future<void> syncUpcomingReminders(List<PhysicalActivity> activities) async {
    await init();
    final settings = await loadSettings();

    for (final act in activities) {
      if (act.id == null) continue;
      if (settings.enabled && settings.isReminderInFuture(act.activityDate)) {
        await scheduleReminderForActivity(act);
      } else {
        await cancelReminderForActivity(act.id!);
      }
    }
  }

  /// Déclenche une notification test immédiate représentant le rappel 5 minutes avant la séance
  Future<void> showInstantTestNotification() async {
    await init();
    await _plugin.show(
      id: _testNotificationId,
      title: '⏰ Rappel séance : Marche (Test)',
      body:
          'Votre séance de marche (30 min) commence dans 5 minutes ! Préparez-vous.',
      notificationDetails: _details,
      payload: 'activity_test',
    );
  }
}
