import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/app_strings.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';

class ChartTimeSelector extends StatelessWidget {
  final TimeRange currentValue;
  final ValueChanged<TimeRange?> onChanged;
  const ChartTimeSelector(
      {super.key, required this.currentValue, required this.onChanged});

  String _getCurrentText(BuildContext context) {
    switch (currentValue) {
      case TimeRange.lastDay:
        return S.of(context).filterLast24h;
      case TimeRange.lastWeek:
        return S.of(context).filterLastWeek;
      case TimeRange.lastMonth:
        return S.of(context).filterLastMonth;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TimeRange>(
      initialValue: currentValue,
      onSelected: onChanged,
      color: AppColors.charcoalBlack,
      elevation: 8,
      offset: const Offset(0, 35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.coolGray),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _getCurrentText(context),
                style: Styles.style10Regular.copyWith(
                  color: AppColors.coolGray,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.coolGray,
              size: 18,
            ),
          ],
        ),
      ),
      // The Menu Items
      itemBuilder: (context) => [
        PopupMenuItem(
          value: TimeRange.lastDay,
          child: Text(
            S.of(context).filterLast24h,
            style: Styles.style10Regular,
          ),
        ),
        PopupMenuItem(
          value: TimeRange.lastWeek,
          child: Text(
            S.of(context).filterLastWeek,
            style: Styles.style10Regular,
          ),
        ),
        PopupMenuItem(
          value: TimeRange.lastMonth,
          child: Text(
            S.of(context).filterLastMonth,
            style: Styles.style10Regular,
          ),
        ),
      ],
    );
  }
}
