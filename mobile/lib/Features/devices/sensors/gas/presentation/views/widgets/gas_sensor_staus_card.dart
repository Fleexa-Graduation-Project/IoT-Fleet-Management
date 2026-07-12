import 'package:fleexa/core/widgets/custom_container.dart';
import 'package:fleexa/core/widgets/device_status_row.dart';
import 'package:fleexa/core/utils/constants/app_strings.dart';
import 'package:flutter/material.dart';

class GasSensorStausCard extends StatelessWidget {
  const GasSensorStausCard({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final deviceStatus = status.toUpperCase() == 'ONLINE'
        ? DeviceStatus.online
        : DeviceStatus.offline;
    return CustomContainer(
        child: DeviceStatusRow(
      status: deviceStatus,
    ));
  }
}
