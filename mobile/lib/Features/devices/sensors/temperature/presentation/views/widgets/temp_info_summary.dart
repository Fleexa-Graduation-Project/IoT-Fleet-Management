
import 'package:fleexa/Features/devices/sensors/temperature/presentation/views/widgets/device_status_list.dart';
import 'package:fleexa/Features/devices/shared/data/models/device_model.dart';
import 'package:fleexa/core/widgets/custom_container.dart';
import 'package:flutter/material.dart';

class TempInfoSummary extends StatelessWidget {
  const TempInfoSummary({super.key, required this.data});
  final DeviceModel data;

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      child: DeviceStatusList(
        tempModel: data,
      ),
    );
  }
}
