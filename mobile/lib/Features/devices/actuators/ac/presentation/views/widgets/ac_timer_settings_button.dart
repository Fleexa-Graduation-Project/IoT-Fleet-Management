import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AcTimerSettingsButton extends StatelessWidget {
  const AcTimerSettingsButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: AppColors.darkGray,
          shape: BoxShape.circle,
        ),
        child: SvgPicture.asset(
          'assets/icons/timer_settings_icon.svg',
          width: 20,
        ),
      ),
    );
  }
}
