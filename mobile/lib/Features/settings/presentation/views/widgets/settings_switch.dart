import 'package:flutter/material.dart';
import '../../../../../core/utils/constants/app_colors.dart';

class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      inactiveTrackColor: AppColors.warmDarkGray,
      activeColor: AppColors.white,
      activeTrackColor: AppColors.darkMaroon,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      inactiveThumbColor: AppColors.white,
      onChanged: onChanged,
    );
  }
}
