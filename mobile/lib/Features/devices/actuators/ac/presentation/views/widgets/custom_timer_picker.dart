import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../../core/utils/constants/app_colors.dart';
import '../../../../../../../../core/utils/constants/app_strings.dart';
import '../../../../../../../../generated/l10n.dart';

class CustomTimerPicker extends StatefulWidget {
  const CustomTimerPicker({
    super.key,
    this.onTimerSet,
    this.onTimeSet,
    this.initialDuration,
    this.initialTime,
    required this.mode,
  });

  final PickerMode mode;

  // Callback for "Duration" mode (e.g., 2 hours 30 mins)
  final ValueChanged<Duration>? onTimerSet;

  // Callback for "Time" mode (e.g., 9:00 AM)
  final ValueChanged<TimeOfDay>? onTimeSet;

  final Duration? initialDuration;
  final TimeOfDay? initialTime;

  @override
  State<CustomTimerPicker> createState() => _CustomTimerPickerState();
}

class _CustomTimerPickerState extends State<CustomTimerPicker> {
  late Duration _selectedDuration;
  late DateTime _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.initialDuration ?? const Duration(hours: 1);

    final now = DateTime.now();
    final time = widget.initialTime ?? TimeOfDay.now();
    _selectedTime =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.nearBlack,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.mode == PickerMode.duration
                    ? S.of(context).setTimer
                    : S.of(context).setTime,
                style: Styles.style16Medium.copyWith(color: AppColors.white),
              ),
              GestureDetector(
                onTap: () => GoRouter.of(context).pop(),
                child:
                    const Icon(Icons.close_rounded, color: AppColors.coolGray),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // PICKER AREA
          Expanded(
            child: CupertinoTheme(
              data: CupertinoThemeData(
                brightness: Brightness.dark,
                textTheme: CupertinoTextThemeData(
                  pickerTextStyle:
                      Styles.style16Medium.copyWith(color: AppColors.white),
                ),
              ),
              child: widget.mode == PickerMode.duration
                  ? CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hm,
                      initialTimerDuration: _selectedDuration,
                      onTimerDurationChanged: (Duration newDuration) {
                        setState(() {
                          _selectedDuration = newDuration;
                        });
                      },
                    )
                  : CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      initialDateTime: _selectedTime,
                      use24hFormat: false,
                      onDateTimeChanged: (DateTime newTime) {
                        setState(() {
                          _selectedTime = newTime;
                        });
                      },
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // CONFIRM BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkMaroon,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (widget.mode == PickerMode.duration) {
                  widget.onTimerSet?.call(_selectedDuration);
                } else {
                  widget.onTimeSet?.call(TimeOfDay.fromDateTime(_selectedTime));
                }
                GoRouter.of(context).pop();
              },
              child: Text(
                S.of(context).set,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
