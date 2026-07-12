import 'package:fleexa/Features/devices/actuators/door_lock/presentation/views/widgets/alerts_section.dart';
import 'package:fleexa/Features/devices/actuators/door_lock/presentation/views/widgets/door_lock_details_header.dart';
import 'package:fleexa/Features/devices/actuators/door_lock/presentation/views/widgets/door_lock_insight.dart';
import 'package:fleexa/Features/devices/shared/presentation/manager/device_alerts_cubit.dart';
import 'package:fleexa/Features/devices/shared/presentation/manager/device_details_cubit.dart';
import 'package:fleexa/core/widgets/custom_refresh_indicator.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../../../core/widgets/custom_appbar.dart';
import '../../../../shared/presentation/manager/device_details_state.dart';
import 'widgets/normal_duration_dialog.dart';

class DoorLockDetailsView extends StatelessWidget {
  const DoorLockDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(
        title: S.of(context).doorLock,
      ),
      body: SafeArea(
        child: CustomRefreshIndicator(
          onRefresh: () async {
            final state = context.read<DeviceDetailsCubit>().state;
            if (state is DeviceDetailsLoaded) {
              final currentDoorId = state.device.deviceId;
              await Future.wait([
                context
                    .read<DeviceDetailsCubit>()
                    .loadDeviceData(currentDoorId),
                context.read<DeviceAlertsCubit>().loadAlerts(currentDoorId),
              ]);
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DoorLockDetailsHeader(),
                  const SizedBox(height: 40),
                  const AlertsSection(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        S.of(context).labelInsights,
                        style: Styles.style18Medium
                            .copyWith(color: AppColors.white),
                      ),
                      IconButton(
                        icon: SvgPicture.asset(
                            'assets/icons/settings_tab_off.svg',
                            width: 24,
                            height: 24),
                        onPressed: () {
                          final detailsCubit =
                              context.read<DeviceDetailsCubit>();
                          int currentLimit = 2;
                          String deviceId = '';

                          if (detailsCubit.state is DeviceDetailsLoaded) {
                            final device =
                                (detailsCubit.state as DeviceDetailsLoaded)
                                    .device;
                            deviceId = device.deviceId;
                            currentLimit = device.normalUnlockDuration.toInt();
                          }

                          final screenContext = context;

                          showDialog(
                            context: context,
                            builder: (dialogContext) => NormalDurationDialog(
                              initialMinutes: currentLimit,
                              onSaved: (newMinutes) {
                                screenContext
                                    .read<DeviceDetailsCubit>()
                                    .setNormalUnlockDuration(
                                        deviceId, newMinutes);
                              },
                            ),
                          );
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  const DoorLockInsight(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
