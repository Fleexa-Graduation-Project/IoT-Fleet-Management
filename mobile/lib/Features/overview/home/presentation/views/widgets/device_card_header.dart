import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../../../core/utils/constants/app_colors.dart';

class DeviceCardHeader extends StatelessWidget {
  const DeviceCardHeader({
    super.key,
    required this.icon,
    required this.statusColor,
    required this.isActuator,
  });

  final String icon;
  final Color statusColor;
  final bool isActuator;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icon
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActuator ? AppColors.bordeaux : AppColors.dimGray,
          ),
          child: SvgPicture.asset(
            icon,
            width: 24,
            height: 24,
            fit: BoxFit.contain,
          ),
        ),

        // Status dot
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: statusColor,
          ),
        ),
      ],
    );
  }
}
