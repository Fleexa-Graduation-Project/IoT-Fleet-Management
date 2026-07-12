import 'package:fleexa/Features/devices/actuators/ac/presentation/views/widgets/custom_slider.dart';
import 'package:fleexa/Features/devices/actuators/ac/presentation/views/widgets/time_button.dart';
import 'package:fleexa/core/widgets/custom_container.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';

import '../../../../../../../../core/utils/constants/app_strings.dart';
import 'custom_timer_picker.dart';

class AcSmartRules extends StatefulWidget {
  const AcSmartRules({
    super.key,
    required this.threshold,
    required this.targetTemp,
    required this.onChanged,
  });

  final int threshold;
  final int targetTemp;
  final ValueChanged<dynamic> onChanged;

  @override
  State<AcSmartRules> createState() => _AcSmartRulesState();
}

class _AcSmartRulesState extends State<AcSmartRules> {
  TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 5, minute: 0);

  void _showTimePicker(bool isStartTime) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: CustomTimerPicker(
          mode: PickerMode.time, // <--- Mode 2
          initialTime: isStartTime ? startTime : endTime,
          onTimeSet: (TimeOfDay time) {
            setState(() {
              if (isStartTime) {
                startTime = time;
              } else {
                endTime = time;
              }
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).smartRules,
          style: Styles.style18Medium.copyWith(color: AppColors.white),
        ),
        const SizedBox(height: 16),
        CustomContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    S.of(context).Threshold,
                    style: Styles.style14Medium.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.threshold}°C',
                    style: Styles.style14Medium.copyWith(
                      color: AppColors.coolGray,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                S.of(context).ThresholdDescription(
                      widget.targetTemp + widget.threshold,
                      widget.targetTemp - widget.threshold,
                    ),
                style: Styles.style12Regular.copyWith(
                  color: AppColors.coolGray,
                ),
              ),
              const SizedBox(height: 12),
              CustomSlider(
                  threshold: widget.threshold, onChanged: widget.onChanged),
              const SizedBox(height: 18),
              Text(
                S.of(context).activeHours,
                style: Styles.style14Medium.copyWith(
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TimeButton(
                      label: S.of(context).starts,
                      time: startTime,
                      onTap: () => _showTimePicker(true),
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: TimeButton(
                      label: S.of(context).ends,
                      time: endTime,
                      onTap: () => _showTimePicker(false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
