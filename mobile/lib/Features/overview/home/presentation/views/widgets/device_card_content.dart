import 'package:flutter/material.dart';

import '../../../../../../core/utils/constants/app_colors.dart';
import '../../../../../../core/utils/constants/styles.dart';

class DeviceCardContent extends StatelessWidget {
  const DeviceCardContent({
    super.key,
    required this.title,
    required this.subtext,
  });

  final String title;
  final String subtext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Styles.style16Medium,
        ),
        const SizedBox(height: 4),
        Text(
          subtext,
          style: Styles.style12Regular.copyWith(
            color: AppColors.mediumGray,
          ),
        ),
      ],
    );
  }
}
