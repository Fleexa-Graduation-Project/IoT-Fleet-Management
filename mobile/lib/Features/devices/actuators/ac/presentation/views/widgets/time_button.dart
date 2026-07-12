import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../../../core/utils/constants/app_colors.dart';
import '../../../../../../../../core/utils/constants/styles.dart';

class TimeButton extends StatefulWidget {
  const TimeButton({
    super.key,
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  State<TimeButton> createState() => _TimeButtonState();
}

class _TimeButtonState extends State<TimeButton> {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dt = DateTime(
        now.year, now.month, now.day, widget.time.hour, widget.time.minute);
    final formattedTime = DateFormat('hh:mm a').format(dt);
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: AppColors.dimGray),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${widget.label} ",
              style: Styles.style14Medium.copyWith(color: AppColors.mediumGray),
            ),
            Text(
              formattedTime,
              style: Styles.style14Medium.copyWith(color: AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}
