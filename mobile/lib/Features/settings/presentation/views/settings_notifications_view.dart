import 'package:fleexa/Features/settings/presentation/manager/notification_settings_cubit.dart';
import 'package:fleexa/core/widgets/disabled_section.dart';
import 'package:fleexa/Features/settings/presentation/views/widgets/settings_notifications_card.dart';
import 'package:fleexa/Features/settings/presentation/views/widgets/settings_switch.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/app_strings.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../manager/notification_settings_state.dart';
import 'widgets/notifications_user_preferences.dart';

class SettingsNotificationsView extends StatelessWidget {
  const SettingsNotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).settingsNotificationsAndAlerts),
        centerTitle: true,
        titleTextStyle: Styles.style20Medium,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 24,
              horizontal: 16,
            ),
            child: BlocBuilder<NotificationSettingsCubit,
                NotificationSettingsState>(
              builder: (context, state) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Push Notifications Card
                    SettingsNotificationsCard(
                      title: S.of(context).settingsPushNotifications,
                      trailingWidget: SettingsSwitch(
                        value: state.isPushEnabled,
                        onChanged: (value) {
                          context
                              .read<NotificationSettingsCubit>()
                              .togglePushNotifications(
                                value,
                                AppConstants.notificationDevices,
                              );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // User Preferences Options
                    DisabledSection(
                      isEnabled: state.isPushEnabled,
                      child: const NotificationsUserPreferences(),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
