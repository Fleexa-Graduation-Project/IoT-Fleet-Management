import 'package:fleexa/Features/devices/shared/data/models/device_model.dart';
import 'package:fleexa/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fleexa/Features/overview/home/presentation/manager/devices_cubit.dart';
import 'package:fleexa/Features/overview/home/presentation/manager/devices_state.dart';
import 'package:go_router/go_router.dart';

import 'gas_sensor_overview.dart';
import 'devices_grid.dart';

class SummariesSection extends StatelessWidget {
  const SummariesSection({super.key});

  List<DeviceModel> _filterDevices(List<DeviceModel> devices) {
    return devices.where((d) => d.type != 'gas-sensor').toList();
  }

  DeviceModel? _extractGasDevice(List<DeviceModel> devices) {
    final index = devices.indexWhere((d) => d.type == 'gas-sensor');
    if (index != -1) {
      return devices[index];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DevicesCubit, DevicesState>(
      builder: (context, state) {
        if (state is DevicesLoading || state is DevicesInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is DevicesError) {
          return Center(child: Text(state.message));
        }

        if (state is DevicesLoaded) {
          final devices = state.devices;

          final filtered = _filterDevices(devices);
          final gasDevice = _extractGasDevice(devices);

          return Column(
            children: [
              if (gasDevice != null)
                GestureDetector(
                  onTap: () =>
                      GoRouter.of(context).pushNamed(AppRouter.gasSensor),
                  child: GasSensorOverview(gasDevice: gasDevice),
                ),
              const SizedBox(height: 24),
              DevicesGrid(devices: filtered),
            ],
          );
        }

        return const SizedBox();
      },
    );
  }
}
