import 'package:fleexa/Features/overview/system_overview/data/models/info_status_model.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';

class InfoStatusRow extends StatelessWidget {
  const InfoStatusRow({super.key, required this.infoStatusModel});
  final InfoStatusModel infoStatusModel;
  bool get isConnected =>
      infoStatusModel.description.toLowerCase() == 'online' ||
      infoStatusModel.description.toLowerCase() == 'connected';
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(infoStatusModel.title,
            style: Styles.style14Medium.copyWith(color: AppColors.white)),
        const Spacer(),
        if (S.of(context).labelSystemStatus == infoStatusModel.title) ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color:
                  isConnected ? AppColors.emeraldGreen : AppColors.crimsonRed,
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
        ] else ...[
          Text(
            infoStatusModel.description,
            style: Styles.style12Medium.copyWith(color: AppColors.white),
          ),
        ]
      ],
    );
  }
}
