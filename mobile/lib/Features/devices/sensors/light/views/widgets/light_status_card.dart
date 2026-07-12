import 'package:fleexa/core/widgets/custom_container.dart';
import 'package:fleexa/core/widgets/custom_container_row.dart';
import 'package:fleexa/core/widgets/device_status_row.dart';
import 'package:fleexa/core/utils/constants/app_strings.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';

class LightStatusCard extends StatelessWidget {
  const LightStatusCard({
    super.key,
    required this.status,
    required this.operationalState,
  });

  final String status;
  final String operationalState;

  @override
  Widget build(BuildContext context) {
    final deviceStatus = status.toUpperCase() == 'ONLINE'
        ? DeviceStatus.online
        : DeviceStatus.offline;

    return CustomContainer(
      child: Column(
        children: [
          DeviceStatusRow(
            status: deviceStatus,
          ),
          const SizedBox(height: 12),
          CustomContainerRow(
            title: S.of(context).lightstatus,
            value: operationalState,
          ),
        ],
      ),
    );
  }
}
