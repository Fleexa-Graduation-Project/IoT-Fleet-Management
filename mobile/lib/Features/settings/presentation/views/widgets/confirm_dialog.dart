import 'package:flutter/material.dart';
import 'package:fleexa/generated/l10n.dart';

import 'package:go_router/go_router.dart';

import '../../../../../core/utils/constants/app_colors.dart';
import '../../../../../core/utils/constants/app_strings.dart';
import '../../../../../core/utils/constants/styles.dart';

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.onConfirm,
    this.dialogType = DialogType.deleteAccount,
  });

  final VoidCallback onConfirm;
  final DialogType dialogType;

  String get deleteTitle {
    switch (dialogType) {
      case DialogType.deleteAccount:
        return 'Delete Account';
      case DialogType.logout:
        return 'Logout';
    }
  }

  String get deleteMessage {
    switch (dialogType) {
      case DialogType.deleteAccount:
        return 'Are you sure you want to delete your account? This action cannot be undone.';
      case DialogType.logout:
        return 'Are you sure you want to logout?';
    }
  }

  String get confirmButtonText {
    switch (dialogType) {
      case DialogType.deleteAccount:
        return 'Delete';
      case DialogType.logout:
        return 'Logout';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.darkGray,
      title: Text(deleteTitle,
          style: Styles.style18SemiBold.copyWith(color: AppColors.white)),
      content: Text(deleteMessage,
          style: Styles.style14Medium.copyWith(color: AppColors.coolGray)),
      actions: [
        TextButton(
          onPressed: () => GoRouter.of(context).pop(),
          child: Text(S.of(context).cancel,
              style: const TextStyle(color: AppColors.white)),
        ),
        TextButton(
          onPressed: () {
            onConfirm();
          },
          child: Text(
            confirmButtonText,
            style: const TextStyle(color: AppColors.crimsonRed),
          ),
        ),
      ],
    );
  }
}
