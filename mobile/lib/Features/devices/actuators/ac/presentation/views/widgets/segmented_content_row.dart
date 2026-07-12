import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:flutter/material.dart';

import '../../../../../../../../core/utils/constants/app_colors.dart';

class SegmentedContentRow extends StatelessWidget {
  const SegmentedContentRow({
    super.key,
    required this.title,
    required this.isSelected,
  });

  final String title;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isSelected) ...[
            const Icon(Icons.check, color: AppColors.white, size: 16),
            const SizedBox(width: 6),
          ],
          Text(
            title,
            style: Styles.style12Medium.copyWith(
              color: isSelected ? AppColors.white : AppColors.coolGray,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
