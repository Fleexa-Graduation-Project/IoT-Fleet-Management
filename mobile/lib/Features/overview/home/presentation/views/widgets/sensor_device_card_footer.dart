import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../../../core/utils/constants/app_colors.dart';
import '../../../../../../core/utils/constants/styles.dart';

class SensorDeviceCardFooter extends StatelessWidget {
  const SensorDeviceCardFooter({
    super.key,
    required this.valueLabel,
    required this.valueIcon,
  });

  final String? valueLabel;
  final String? valueIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.charcoalBlack,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: AppColors.darkGray,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            valueIcon!,
            width: 14,
            height: 14,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 4),
          Text(
            valueLabel!,
            style: Styles.style8Medium,
          ),
        ],
      ),
    );
  }
}
