import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.jetBlack,
        titleTextStyle: Styles.style24Medium,
        iconTheme: const IconThemeData(color: AppColors.coolGray),
      ),
      scaffoldBackgroundColor: AppColors.jetBlack,
      primaryColor: AppColors.white,
      fontFamily: 'Rubik',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.wineRed,
        brightness: Brightness.dark,
      ),
    );
  }
}
