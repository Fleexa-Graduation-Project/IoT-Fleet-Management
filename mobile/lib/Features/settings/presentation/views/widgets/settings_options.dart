import 'package:fleexa/Features/auth/presentation/manager/auth_cubit.dart';
import 'package:fleexa/Features/overview/notifications/presentation/manager/notifications_cubit.dart';
import 'package:fleexa/core/router/app_router.dart';
import 'package:fleexa/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/utils/constants/app_strings.dart';
import '../../../../../generated/l10n.dart';
import '../../../../auth/presentation/manager/auth_state.dart';
import 'confirm_dialog.dart';
import 'settings_card.dart';

class SettingsOptions extends StatelessWidget {
  const SettingsOptions({super.key});

  @override
  Widget build(BuildContext context) {
    // final currentLocale = context.watch<LocalizationCubit>().state;
    // final currentLanguage =
    //     currentLocale.languageCode == 'ar' ? AppLanguage.ar : AppLanguage.en;
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          GoRouter.of(context).goNamed(AppRouter.signIn);
        } else if (state is AuthError) {
          AppSnackbar.show(
            context,
            type: SnackBarType.fail,
            message: state.error,
          );
        }
      },
      child: Column(
        children: [
          // Account and Security
          SettingsCard(
            title: S.of(context).settingsAccountAndSecurity,
            icon: Icons.person_outline_rounded,
            forwardArrow: true,
            pageRouteName: AppRouter.settingsAccount,
          ),
          const SizedBox(height: 20),

          // Notifications and Alerts
          SettingsCard(
            title: S.of(context).settingsNotificationsAndAlerts,
            icon: Icons.notifications_none_rounded,
            forwardArrow: true,
            pageRouteName: AppRouter.settingsNotifications,
          ),
          const SizedBox(height: 20),

          // Language
          // SettingsCard(
          //   title: S.of(context).settingsLanguage,
          //   icon: Icons.language_rounded,
          //   dropDown: SettingsDropDown<AppLanguage>(
          //     value: currentLanguage,
          //     items: AppLanguage.values,
          //     labelBuilder: (language) {
          //       return language == AppLanguage.en
          //           ? S.of(context).languageEnglish
          //           : S.of(context).languageArabic;
          //     },
          //     onChanged: (selectedLanguage) {
          //       context
          //           .read<LocalizationCubit>()
          //           .changeLanguage(selectedLanguage.name);
          //     },
          //   ),
          // ),
          // const SizedBox(height: 20),

          // About and Support
          SettingsCard(
            title: S.of(context).settingsAboutAndSupport,
            icon: Icons.info_outline_rounded,
            forwardArrow: true,
            pageRouteName: AppRouter.settingsAboutSupport,
          ),
          const SizedBox(height: 20),

          // Log Out
          SettingsCard(
            title: S.of(context).settingsLogOut,
            icon: Icons.logout,
            onTap: () {
              showDialog(
                context: context,
                builder: (dialogContext) => ConfirmDialog(
                  dialogType: DialogType.logout,
                  onConfirm: () {
                    GoRouter.of(context).pop(dialogContext);
                    context.read<NotificationsCubit>().clearData();
                    context.read<AuthCubit>().signOut();
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
