import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:fleexa/Features/devices/actuators/ac/presentation/views/widgets/segmented_content_row.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ControlModeToggle extends StatefulWidget {
  const ControlModeToggle({
    super.key,
    required this.controlMode,
    required this.onModeChanged,
  });

  final int controlMode;
  final ValueChanged<int> onModeChanged;

  @override
  State<ControlModeToggle> createState() => _ControlModeToggleState();
}

class _ControlModeToggleState extends State<ControlModeToggle> {
  @override
  Widget build(BuildContext context) {
    return CustomSlidingSegmentedControl<int>(
      initialValue: widget.controlMode,
      isStretch: true,

      // Container Style
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.darkGray, width: 2),
      ),

      // Thumb Style (the moving part)
      thumbDecoration: BoxDecoration(
        color: AppColors.wineRed,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      // Gap between container edge and thumb
      innerPadding: const EdgeInsets.all(2),

      // Animation Settings
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,

      // The Content
      children: {
        0: SegmentedContentRow(
          title: S.of(context).autoMode,
          isSelected: widget.controlMode == 0,
        ),
        1: SegmentedContentRow(
          title: S.of(context).manualMode,
          isSelected: widget.controlMode == 1,
        ),
      },
      onValueChanged: widget.onModeChanged,
    );
  }
}
