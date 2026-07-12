import 'package:fleexa/Features/overview/home/presentation/views/widgets/device_card.dart';
import 'package:fleexa/core/router/app_router.dart';
import 'package:fleexa/core/utils/constants/app_strings.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';

import '../../../../../devices/shared/data/models/device_model.dart';

class DeviceCardList extends StatelessWidget {
  const DeviceCardList({
    super.key,
    required this.devices,
    required this.isDoorLocked,
    required this.isAcOn,
    required this.onDoorToggle,
    required this.onAcToggle,
  });

  final List<DeviceModel> devices;
  final bool isDoorLocked;
  final bool isAcOn;
  final ValueChanged<bool>? onDoorToggle;
  final ValueChanged<bool>? onAcToggle;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: devices.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final DeviceModel device = devices[index];
        String title = '';
        String subtext = '';
        String route = '';
        String mainIcon = '';
        String? valueIcon;
        DeviceType type = DeviceType.sensor;
        bool isOn = false;
        ValueChanged<bool>? onToggle;

        switch (device.type) {
          case 'door-locker':
          case 'door-actuator':
            title = S.of(context).doorLock;
            subtext = isDoorLocked
                ? S.of(context).doorLockedStatus
                : S.of(context).doorUnlockedStatus;
            route = AppRouter.doorLockControl;
            mainIcon = 'assets/icons/door_lock_actuator.svg';
            type = DeviceType.actuator;
            isOn = isDoorLocked;
            onToggle = onDoorToggle;

            break;
          case 'ac-curtain':
          case 'ac-actuator':
            title = S.of(context).ac;
            subtext = S.of(context).target;
            route = AppRouter.acControl;
            mainIcon = 'assets/icons/ac_actuator.svg';
            type = DeviceType.actuator;
            isOn = isAcOn;
            onToggle = onAcToggle;
            break;

          case 'gas-sensor':
            title = S.of(context).gasSensor;
            subtext =
                S.of(context).gasStatus; // Or use device.operationalState!
            route = AppRouter.gasSensor;
            mainIcon = 'assets/icons/gas_sensor.svg';
            type = DeviceType.sensor;
            valueIcon = 'assets/icons/ac_airwaves.svg';
            break;

          case 'light-sensor':
            title = S.of(context).lightSensor;
            subtext = S.of(context).lightstatus;
            route = AppRouter.lightSensor;
            mainIcon = 'assets/icons/light_sensor.svg';
            type = DeviceType.sensor;
            valueIcon = 'assets/icons/ac_heating.svg';
            break;

          case 'temp-sensor':
            title = S.of(context).temperature;
            subtext = S.of(context).temperatureStatus;
            route = AppRouter.temperatureSensor;
            mainIcon = 'assets/icons/temp_sensor.svg';
            type = DeviceType.sensor;
            valueIcon = 'assets/icons/temp_sensor.svg';
            break;
        }

        return DeviceCard(
          title: title,
          subtext: device.operationalState.isNotEmpty
              ? device.operationalState
              : subtext,
          pageRouteName: route,
          icon: mainIcon,
          type: type,
          isOn: isOn,
          onToggle: onToggle,
          valueIcon: valueIcon,
          statusColor: device.indicatorColor,
          valueLabel:
              device.displayValue.isNotEmpty ? device.displayValue : null,
        );
      },
    );
  }
}
