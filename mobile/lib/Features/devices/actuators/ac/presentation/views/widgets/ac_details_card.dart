import 'package:fleexa/Features/devices/shared/presentation/manager/device_details_cubit.dart';
import 'package:fleexa/core/widgets/custom_container.dart';
import 'package:fleexa/core/widgets/device_status_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/widgets/custom_container_row.dart';
import '../../../../../../../../core/utils/constants/app_strings.dart';
import '../../../../../../../../generated/l10n.dart';
import '../../../../../../../core/widgets/app_error.dart';
import '../../../../../../../core/widgets/skelton.dart';
import '../../../../../shared/presentation/manager/device_details_state.dart';

class AcDetailsCard extends StatelessWidget {
  const AcDetailsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceDetailsCubit, DeviceDetailsState>(
      builder: (context, state) {
        if (state is DeviceDetailsLoading || state is DeviceDetailsInitial) {
          return const Skelton(height: 220, width: double.infinity);
        } else if (state is DeviceDetailsError) {
          return CustomContainer(
            child: AppError(message: state.message),
          );
        } else if (state is DeviceDetailsLoaded) {
          final device = state.device;
          final status = device.status.toUpperCase() == 'ONLINE'
              ? DeviceStatus.online
              : DeviceStatus.offline;
          return CustomContainer(
            child: Column(
              children: [
                DeviceStatusRow(
                  status: status,
                ),
                // const SizedBox(height: 16),
                // CustomContainerRow(
                //   title: S.of(context).controlType,
                //   value: S.of(context).autoMode,
                // ),
                const SizedBox(height: 16),
                CustomContainerRow(
                  title: 'Power State',
                  value: device.payload['power_state'] ?? 'Unknown',
                ),
                const SizedBox(height: 16),
                CustomContainerRow(
                  title: S.of(context).mode,
                  value: device.payload['mode'] ?? 'Unknown',
                ),
                const SizedBox(height: 16),
                CustomContainerRow(
                  title: 'Room Temp',
                  value: '${device.payload['inside_temp'] ?? '--'}° C',
                ),
                const SizedBox(height: 16),
                CustomContainerRow(
                  title: S.of(context).target,
                  value:
                      '${(device.payload['target_temp'] as num?)?.round() ?? '--'}° C',
                ),
                // const SizedBox(height: 16),
                // CustomContainerRow(
                //   title: 'Time Remaining',
                //   value: device.payload['time_remaining'] ?? '--',
                // ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
