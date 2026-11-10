/// Modèle des réglages de notifications intelligentes pour les séances d'activité physique.
/// Les rappels sont déclenchés automatiquement [leadTimeMinutes] (5 min) avant l'heure prévue de chaque séance.
class ActivityReminderSettings {
  final bool enabled;
  final int leadTimeMinutes;

  const ActivityReminderSettings({
    this.enabled = true,
    this.leadTimeMinutes = 5,
  });

  /// Calcule l'heure exacte de déclenchement du rappel pour une séance donnée
  DateTime calculateReminderTime(DateTime sessionDate) {
    return sessionDate.subtract(Duration(minutes: leadTimeMinutes));
  }

  /// Indique si le rappel pour cette séance se situe dans le futur par rapport à [reference]
  bool isReminderInFuture(DateTime sessionDate, [DateTime? reference]) {
    final now = reference ?? DateTime.now();
    return calculateReminderTime(sessionDate).isAfter(now);
  }

  ActivityReminderSettings copyWith({
    bool? enabled,
    int? leadTimeMinutes,
  }) {
    return ActivityReminderSettings(
      enabled: enabled ?? this.enabled,
      leadTimeMinutes: leadTimeMinutes ?? this.leadTimeMinutes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'leadTimeMinutes': leadTimeMinutes,
    };
  }

  factory ActivityReminderSettings.fromMap(Map<String, dynamic> map) {
    return ActivityReminderSettings(
      enabled: map['enabled'] as bool? ?? true,
      leadTimeMinutes: (map['leadTimeMinutes'] as num?)?.toInt() ?? 5,
    );
  }
}
