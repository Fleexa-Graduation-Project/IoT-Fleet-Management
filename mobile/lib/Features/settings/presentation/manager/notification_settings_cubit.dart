import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/push_notification_service.dart';
import 'notification_settings_state.dart';

class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  final PushNotificationService _notificationService;
  NotificationSettingsCubit(this._notificationService)
      : super(NotificationSettingsState());

  // 1. load Settings from SharedPreferences when the cubit is initialized
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    emit(state.copyWith(
      isPushEnabled: prefs.getBool('isPushEnabled') ?? true,
      criticalAlerts: prefs.getBool('criticalAlerts') ?? true,
      warningAlerts: prefs.getBool('warningAlerts') ?? true,
    ));
    // await syncSubscriptions();
  }

  // 2. sync subscriptions with firebase
  Future<void> syncSubscriptions() async {
    log("Syncing preferences with backend...");
    await _notificationService.updatePreferences(
      isPushEnabled: state.isPushEnabled,
      criticalAlerts: state.criticalAlerts,
      warningAlerts: state.warningAlerts,
    );
  }

  // 3. toggle Master Push Notifications
  Future<void> togglePushNotifications(
      bool value, List<String> userDeviceIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPushEnabled', value);
    emit(state.copyWith(isPushEnabled: value));

    await syncSubscriptions();
  }

  // 4. toggle Critical Alerts
  Future<void> toggleCriticalAlerts(
      bool value, List<String> userDeviceIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('criticalAlerts', value);
    emit(state.copyWith(criticalAlerts: value));

    await syncSubscriptions();
  }

  // 5. toggle Warning Alerts
  Future<void> toggleWarningAlerts(
      bool value, List<String> userDeviceIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('warningAlerts', value);
    emit(state.copyWith(warningAlerts: value));

    await syncSubscriptions();
  }
}
