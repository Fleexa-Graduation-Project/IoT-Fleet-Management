import 'package:fleexa/Features/devices/actuators/door_lock/presentation/manager/door_lock_cubit.dart';
import 'package:fleexa/Features/devices/actuators/door_lock/presentation/views/widgets/device_pic.dart';
import 'package:fleexa/Features/devices/actuators/door_lock/presentation/views/widgets/recent_events_list.dart';
import 'package:fleexa/Features/devices/actuators/door_lock/presentation/views/widgets/upper_container_content.dart';
import 'package:fleexa/Features/devices/shared/presentation/manager/device_details_cubit.dart';
import 'package:fleexa/core/router/app_router.dart';
import 'package:fleexa/core/widgets/app_loading.dart';
import 'package:fleexa/core/widgets/custom_appbar.dart';
import 'package:fleexa/core/widgets/custom_container.dart';
import 'package:fleexa/core/widgets/custom_refresh_indicator.dart';
import 'package:fleexa/core/widgets/error_page.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/presentation/manager/device_details_state.dart';
import '../manager/door_lock_state.dart';

class DoorLockControlView extends StatefulWidget {
  const DoorLockControlView({super.key});

  @override
  State<DoorLockControlView> createState() => _DoorLockControlViewState();
}

class _DoorLockControlViewState extends State<DoorLockControlView> {
  List<dynamic> localEvents = [];
  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(
        title: S.of(context).doorLock,
        detailsPage: AppRouter.doorLockDetails,
      ),
      body: BlocBuilder<DeviceDetailsCubit, DeviceDetailsState>(
        builder: (context, state) {
          if (state is DeviceDetailsLoading || state is DeviceDetailsInitial) {
            return const AppLoading();
          } else if (state is DeviceDetailsError) {
            return ErrorPage(
              onRetry: () {
                final currentDoorId = context.read<DoorLockCubit>().deviceId;
                context
                    .read<DeviceDetailsCubit>()
                    .loadDeviceData(currentDoorId);
              },
              type: state.errorType,
            );
          } else if (state is DeviceDetailsLoaded) {
            final device = state.device;

            if (!_isInitialized) {
              final bool isLockedFromPayload =
                  device.payload['lock_state'] == 'LOCKED';

              WidgetsBinding.instance.addPostFrameCallback((_) {
                context
                    .read<DoorLockCubit>()
                    .initializeState(isLockedFromPayload);
              });

              localEvents = List.from(
                  (device.payload['recent_events'] as List? ?? []).take(5));
              _isInitialized = true;
            }

            return SafeArea(
              child: CustomRefreshIndicator(
                onRefresh: () async {
                  _isInitialized = false;
                  final currentDoorId = context.read<DoorLockCubit>().deviceId;
                  await context
                      .read<DeviceDetailsCubit>()
                      .loadDeviceData(currentDoorId);
                },
                child: Center(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 52),
                      child: Column(
                        children: [
                          const SizedBox(height: 32),
                          const DevicePic(),
                          const SizedBox(height: 72),
                          CustomContainer(
                            child: BlocBuilder<DoorLockCubit, DoorLockState>(
                              builder: (context, doorState) {
                                bool isLocked = context
                                    .read<DoorLockCubit>()
                                    .isCurrentlyLocked;
                                if (doorState is DoorLockUpdated) {
                                  isLocked = doorState.isLocked;
                                }
                                return UpperContainerContent(
                                  isLocked: isLocked,
                                  onToggle: (value) {
                                    setState(() {
                                      final newLockState = !isLocked;
                                      localEvents.insert(0, {
                                        "event": newLockState
                                            ? "Door locked"
                                            : "Door unlocked",
                                        "time": "Just now",
                                      });

                                      if (localEvents.length > 5) {
                                        localEvents.removeLast();
                                      }

                                      context
                                          .read<DoorLockCubit>()
                                          .toggleLock();
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 36),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                S.of(context).recentActivities,
                                style: Styles.style18Medium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          CustomContainer(
                              child: RecentEventsList(events: localEvents)),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}
