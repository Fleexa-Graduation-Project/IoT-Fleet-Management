class NotificationSettingsState {
  final bool isPushEnabled;
  final bool criticalAlerts;
  final bool warningAlerts;

  NotificationSettingsState({
    this.isPushEnabled = true,
    this.criticalAlerts = true,
    this.warningAlerts = true,
  });

  NotificationSettingsState copyWith({
    bool? isPushEnabled,
    bool? criticalAlerts,
    bool? warningAlerts,
  }) {
    return NotificationSettingsState(
      isPushEnabled: isPushEnabled ?? this.isPushEnabled,
      criticalAlerts: criticalAlerts ?? this.criticalAlerts,
      warningAlerts: warningAlerts ?? this.warningAlerts,
    );
  }
}
