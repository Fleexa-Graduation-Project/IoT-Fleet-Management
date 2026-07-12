import 'package:fleexa/Features/overview/system_overview/data/models/info_status_model.dart';
import 'package:fleexa/Features/overview/system_overview/presentation/views/widgets/info_status_list.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';

class SystemStatusCard extends StatelessWidget {
  const SystemStatusCard(
      {super.key, required this.systemStatus, required this.devicesOnline});

  final String systemStatus;
  final String devicesOnline;
  @override
  Widget build(BuildContext context) {
    final infoItems = [
      InfoStatusModel(
        title: S.of(context).labelSystemStatus,
        description: systemStatus,
      ),
      InfoStatusModel(
        title: S.of(context).labelDevicesOnline,
        description: devicesOnline,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.charcoalBlack,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InfoStatusList(items: infoItems),
    );
  }
}
