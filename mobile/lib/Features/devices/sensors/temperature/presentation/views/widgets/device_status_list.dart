import 'package:fleexa/Features/devices/sensors/temperature/data/models/device_status_model.dart';

import 'package:fleexa/Features/devices/sensors/temperature/presentation/views/widgets/device_status_row.dart';
import 'package:fleexa/Features/devices/shared/data/models/device_model.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';

class DeviceStatusList extends StatelessWidget {


  const DeviceStatusList({
    super.key,

    required this.tempModel,
  });
  final DeviceModel tempModel;
  @override
  Widget build(BuildContext context) {
        final List<DeviceStatusModel> deviceStatusItems = [
      DeviceStatusModel(
        status: S.of(context).labelSystemStatus,
        description: '',
        isConnected: true,
      ),
      DeviceStatusModel(
        status: S.of(context).temperatureStatus,
        description: S.of(context).statusAboveHigh,
      ),
    ];
    return Column(
      children: deviceStatusItems.map((item) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: item.status == S.of(context).temperatureStatus ? 0 : 12),
          child: DeviceStatusRow(
            tempModel: tempModel,
            deviceStatusModel: item,
          ),
        );
      }).toList(),
    );
  }
}
