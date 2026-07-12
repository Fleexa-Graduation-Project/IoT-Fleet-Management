import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

import '../../../../../../../../core/utils/constants/app_colors.dart';

class CustomSlider extends StatelessWidget {
  const CustomSlider({
    super.key,
    required this.threshold,
    required this.onChanged,
  });
  final ValueChanged<dynamic> onChanged;
  final int threshold;

  @override
  Widget build(BuildContext context) {
    return SfSliderTheme(
      data: const SfSliderThemeData(
        activeTrackHeight: 6,
        inactiveTrackHeight: 6,
        thumbRadius: 8,
        thumbColor: AppColors.darkMaroon,
        activeTrackColor: AppColors.darkMaroon,
        inactiveTrackColor: AppColors.dimGray,
        overlayRadius: 0,
      ),
      child: SfSlider(
        min: 1.0,
        max: 6.0,
        value: threshold.toDouble(),
        interval: 1,
        stepSize: 1,
        showTicks: false,
        showLabels: false,
        onChanged: onChanged,
      ),
    );
  }
}
