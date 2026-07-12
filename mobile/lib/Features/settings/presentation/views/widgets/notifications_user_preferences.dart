import 'package:fleexa/Features/settings/presentation/manager/notification_settings_cubit.dart';
import 'package:fleexa/core/utils/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../generated/l10n.dart';
import '../../manager/notification_settings_state.dart';
import 'settings_notifications_card.dart';
import 'settings_checkbox.dart';

class NotificationsUserPreferences extends StatelessWidget {
  const NotificationsUserPreferences({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationSettingsCubit, NotificationSettingsState>(
      builder: (context, state) {
        return Column(
          children: [
            // Critical Alerts Option Card
            SettingsNotificationsCard(
              title: S.of(context).SettingsCriticalAlerts,
              subtitle: S.of(context).settingsCriticalAlertsDescription,
              onTap: () {
                context.read<NotificationSettingsCubit>().toggleCriticalAlerts(
                    !state.criticalAlerts, AppConstants.notificationDevices);
              },
              trailingWidget: SettingsCheckbox(
                value: state.criticalAlerts,
                onChanged: (value) {
                  context
                      .read<NotificationSettingsCubit>()
                      .toggleCriticalAlerts(
                          value, AppConstants.notificationDevices);
                },
              ),
            ),
            const SizedBox(height: 16),

            // Warning Alerts Option Card
            SettingsNotificationsCard(
              title: S.of(context).settingsWarningAlerts,
              subtitle: S.of(context).settingsWarningAlertsDescription,
              onTap: () {
                context.read<NotificationSettingsCubit>().toggleWarningAlerts(
                    !state.warningAlerts, AppConstants.notificationDevices);
              },
              trailingWidget: SettingsCheckbox(
                value: state.warningAlerts,
                onChanged: (value) {
                  context.read<NotificationSettingsCubit>().toggleWarningAlerts(
                      value, AppConstants.notificationDevices);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
