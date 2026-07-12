import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/utils/constants/app_colors.dart';

class CustomSwitch extends StatelessWidget {
  const CustomSwitch({
    super.key,
    required this.isOn,
    required this.onToggle,
  });

  final bool isOn;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    return AnimatedToggleSwitch<bool>.dual(
      current: isOn,
      first: false,
      second: true,
      onChanged: onToggle,
      height: 24,
      borderWidth: 0,
      indicatorSize: const Size(18, 18),
      spacing: 2,
      style: ToggleStyle(
        backgroundColor: isOn ? AppColors.darkMaroon : AppColors.dimGray,
        indicatorColor: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
      ),
    );
  }
}
