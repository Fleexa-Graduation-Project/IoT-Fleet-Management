import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/utils/constants/app_colors.dart';

class SettingsCheckbox extends StatelessWidget {
  const SettingsCheckbox({
    super.key,
    required this.onChanged,
    required this.value,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: value,
      activeColor: AppColors.burgundy,
      checkColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}
