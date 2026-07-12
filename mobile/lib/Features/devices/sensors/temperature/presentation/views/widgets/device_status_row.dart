import 'package:fleexa/Features/devices/sensors/temperature/data/models/device_status_model.dart';
import 'package:fleexa/Features/devices/sensors/temperature/presentation/views/widgets/connected_label.dart';
import 'package:fleexa/Features/devices/sensors/temperature/presentation/views/widgets/not_connected_label.dart';
import 'package:fleexa/Features/devices/shared/data/models/device_model.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:flutter/material.dart';

class DeviceStatusRow extends StatelessWidget {
  const DeviceStatusRow({
    super.key,
    required this.deviceStatusModel,
    required this.tempModel,
  });

  final DeviceStatusModel deviceStatusModel;
  final DeviceModel tempModel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          deviceStatusModel.status,
          style: Styles.style14Medium.copyWith(color: AppColors.white),
        ),
        const Spacer(),
        if (deviceStatusModel.isConnected)
          tempModel.status == 'ONLINE'
              ? const ConnectedLabel()
              : const NotConnectedLabel()
        else
          Text(
            tempModel.operationalState,
            style: Styles.style12Medium.copyWith(
              color: AppColors.white50,
            ),
          ),
      ],
    );
  }
}
