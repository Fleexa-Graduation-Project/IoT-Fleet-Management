import 'package:flutter/material.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';

import '../utils/constants/app_colors.dart';
import '../utils/constants/styles.dart';

class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context, {
    required SnackBarType type,
    required String message,
  }) {
    IconSnackBar.show(
      context,
      label: message,
      maxLines: 5,
      snackBarType: type,
      backgroundColor: _getBackgroundColor(type),
      labelTextStyle: Styles.style14Medium.copyWith(
        color: AppColors.white,
      ),
    );
  }

  static Color? _getBackgroundColor(SnackBarType type) {
    switch (type) {
      case SnackBarType.alert:
        return AppColors.dimGray;
      case SnackBarType.fail:
        return AppColors.wineRed;
      case SnackBarType.success:
        return const Color.fromARGB(255, 24, 137, 39);
    }
  }
}
