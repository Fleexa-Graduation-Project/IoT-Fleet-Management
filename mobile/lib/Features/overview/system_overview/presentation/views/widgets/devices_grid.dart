import 'package:fleexa/Features/devices/shared/data/models/device_model.dart';
import 'package:flutter/material.dart';

import 'package:fleexa/Features/overview/system_overview/data/models/device_quick_item.dart';
import 'package:fleexa/core/router/app_router.dart';
import 'package:fleexa/core/utils/constants/assets.dart';
import 'package:fleexa/generated/l10n.dart';

import 'device_overview_card.dart';

class DevicesGrid extends StatelessWidget {
  const DevicesGrid({
    super.key,
    required this.devices,
  });

  final List<DeviceModel> devices;

  DeviceQuickItem _mapQuickItem(DeviceModel device, BuildContext context) {
    switch (device.type) {
      case 'light-sensor':
        return DeviceQuickItem(
          iconPath: AppAssets.iconsLight,
          path: AppRouter.lightSensor,
          title: S.of(context).lightSensor,
          deviceDesc: S.of(context).avergeBrightness,
        );

      case 'door-actuator':
        return DeviceQuickItem(
          iconPath: AppAssets.iconsDoor,
          path: AppRouter.doorLockControl,
          title: S.of(context).doorLock,
          deviceDesc: S.of(context).lastActivity,
        );

      case 'ac-actuator':
        return DeviceQuickItem(
          iconPath: AppAssets.iconsAc,
          path: AppRouter.acControl,
          title: S.of(context).ac,
          deviceDesc: S.of(context).target,
        );

      case 'temp-sensor':
        return DeviceQuickItem(
          iconPath: AppAssets.iconsTemperature,
          path: AppRouter.temperatureSensor,
          title: S.of(context).temperature,
          deviceDesc: S.of(context).currentTemperature,
        );

      default:
        return const DeviceQuickItem(
          iconPath: '',
          path: '/',
          title: '',
          deviceDesc: '',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        final quick = _mapQuickItem(device, context);

        return DeviceOverviewCard(
     
          initialDeviceModel: device,
          quickDevice: quick,
        );
      },
    );
  }
}
