import 'package:fleexa/Features/settings/presentation/views/widgets/account_card.dart';
import 'package:fleexa/core/router/app_router.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsAccountView extends StatelessWidget {
  const SettingsAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.white),
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: Text(S.of(context).settingsAccountAndSecurity,
            style: Styles.style20Medium),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              AccountCard(
                title: S.of(context).settingsProfile,
                forwardArrow: true,
                onTap: () {
                  context.pushNamed(AppRouter.settingsProfile);
                },
              ),
              const SizedBox(height: 18),
              AccountCard(
                title: S.of(context).settingsChangePassword,
                onTap: () {
                  context.pushNamed(AppRouter.changePassword);
                },
              ),
              const SizedBox(height: 18),
              AccountCard(
                title: S.of(context).settingsDeleteAccount,
                onTap: () {
                  GoRouter.of(context).pushNamed(AppRouter.deleteAccount);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
