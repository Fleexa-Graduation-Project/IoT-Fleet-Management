import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/app_strings.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';

class DeviceStatusRow extends StatelessWidget {
  const DeviceStatusRow({super.key, required this.status});

  final DeviceStatus status;

  bool get isConnected => status == DeviceStatus.online;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          S.of(context).deviceStatus,
          style: Styles.style14Medium.copyWith(color: AppColors.white),
        ),
        const Spacer(),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isConnected ? AppColors.emeraldGreen : AppColors.crimsonRed,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          isConnected
              ? S.of(context).statusConnected
              : S.of(context).statusDisconnected,
          style: Styles.style12Medium.copyWith(
            color: AppColors.coolGray,
          ),
        ),
      ],
    );
  }
}
