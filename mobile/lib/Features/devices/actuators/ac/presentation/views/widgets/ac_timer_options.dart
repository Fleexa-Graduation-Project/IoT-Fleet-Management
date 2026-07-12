import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:flutter/material.dart';

class AcTimerOptions extends StatelessWidget {
  const AcTimerOptions({
    super.key,
    required this.selectedOption,
    required this.selectedMin,
    required this.onOptionChanged,
  });

  final int? selectedOption;
  final int? selectedMin;
  final ValueChanged<int> onOptionChanged;

  @override
  Widget build(BuildContext context) {
    final List<int> timeOptions = [2, 4, 6, 8, 10, 12];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: timeOptions.map(
          (hours) {
            final bool isSelected =
                (selectedOption == hours && (selectedMin == 0));
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: () => onOptionChanged(hours),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.wineRed : Colors.transparent,
                  ),
                  child: Text(
                    '${hours}H',
                    style: Styles.style14Medium.copyWith(
                      color: isSelected ? Colors.white : AppColors.coolGray,
                    ),
                  ),
                ),
              ),
            );
          },
        ).toList(),
      ),
    );
  }
}
