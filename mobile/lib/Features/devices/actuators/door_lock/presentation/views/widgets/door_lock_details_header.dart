import 'package:fleexa/Features/devices/shared/presentation/manager/device_details_cubit.dart';
import 'package:fleexa/core/widgets/app_error.dart';
import 'package:fleexa/core/widgets/custom_container.dart';
import 'package:fleexa/core/widgets/skelton.dart';
import 'package:fleexa/core/utils/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/widgets/custom_container_row.dart';
import '../../../../../../../core/widgets/device_status_row.dart';
import '../../../../../../../../generated/l10n.dart';
import '../../../../../shared/presentation/manager/device_details_state.dart';

class DoorLockDetailsHeader extends StatelessWidget {
  const DoorLockDetailsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceDetailsCubit, DeviceDetailsState>(
      builder: (context, state) {
        if (state is DeviceDetailsLoading || state is DeviceDetailsInitial) {
          return const Skelton(height: 90, width: double.infinity);
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
                const SizedBox(height: 16),
                CustomContainerRow(
                  title: S.of(context).currentStatus,
                  value: device.operationalState,
                )
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
