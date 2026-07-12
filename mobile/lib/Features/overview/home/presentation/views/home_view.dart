import 'package:fleexa/Features/devices/actuators/door_lock/presentation/manager/door_lock_cubit.dart';

import 'package:fleexa/Features/overview/home/presentation/manager/devices_cubit.dart';
import 'package:fleexa/Features/overview/home/presentation/views/widgets/device_card_list.dart';
import 'package:fleexa/Features/overview/home/presentation/views/widgets/home_appbar.dart';
import 'package:fleexa/core/widgets/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/constants/app_strings.dart';
import '../../../../../core/widgets/error_page.dart';
import '../../../../../core/widgets/skelton.dart';
import '../../../../devices/actuators/ac/presentation/manager/ac_control_cubit.dart';
import '../../../../devices/actuators/ac/presentation/manager/ac_control_state.dart';
import '../../../../devices/actuators/door_lock/presentation/manager/door_lock_state.dart';
import '../manager/devices_state.dart';
import 'widgets/devices_section_header.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<DevicesCubit, DevicesState>(
          builder: (context, state) {
            if (state is DevicesLoading || state is DevicesInitial) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 24,
                    left: 24,
                    right: 24,
                    bottom: 8,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const HomeAppbar(),
                      const SizedBox(height: 12),
                      DevicesSectionHeader(
                        currentFilter: DeviceFilter.all,
                        onFilterChanged: (_) {},
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: GridView.builder(
                          itemCount: 5,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                          itemBuilder: (context, index) {
                            return const Skelton(
                              height: double.infinity,
                              width: double.infinity,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else if (state is DevicesError) {
              return ErrorPage(
                type: state.errorType,
                onRetry: () => context.read<DevicesCubit>().fetchDevices(),
              );
            } else if (state is DevicesLoaded) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 24,
                    left: 24,
                    right: 24,
                    bottom: 8,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const HomeAppbar(),
                      const SizedBox(height: 12),
                      DevicesSectionHeader(
                        currentFilter: state.currentFilter,
                        onFilterChanged: (value) {
                          if (value != null) {
                            context.read<DevicesCubit>().filterDevices(value);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: BlocListener<DoorLockCubit, DoorLockState>(
                          listener: (context, doorState) {
                            if (doorState is DoorLockUpdated) {
                              final currentDoorId =
                                  context.read<DoorLockCubit>().deviceId;
                              context
                                  .read<DevicesCubit>()
                                  .updateDeviceStateLocally(
                                    currentDoorId,
                                    doorState.isLocked ? 'LOCKED' : 'UNLOCKED',
                                  );
                            }
                          },
                          child: CustomRefreshIndicator(
                            onRefresh: () async =>
                                context.read<DevicesCubit>().fetchDevices(),
                            child: state.devices.isEmpty
                                ? SingleChildScrollView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    child: SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.5,
                                      child: Center(
                                        child: Text(
                                          'No devices available',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : DeviceCardList(
                                    isAcOn: () {
                                      final acCubit =
                                          context.watch<AcControlCubit>();

                                      if (acCubit.state is AcControlInitial) {
                                        if (state.devices.isEmpty) return false;

                                        final acIndex = state.devices
                                            .indexWhere(
                                                (d) => d.type == 'ac-actuator');

                                        if (acIndex != -1) {
                                          return state.devices[acIndex]
                                                  .operationalState ==
                                              'ON';
                                        }

                                        return false;
                                      }

                                      return acCubit.powerOn;
                                    }(),
                                    isDoorLocked: () {
                                      final doorCubit =
                                          context.watch<DoorLockCubit>();

                                      if (doorCubit.state is DoorLockInitial) {
                                        if (state.devices.isEmpty) return true;

                                        final doorIndex = state.devices
                                            .indexWhere((d) =>
                                                d.type == 'door-actuator');

                                        if (doorIndex != -1) {
                                          return state.devices[doorIndex]
                                                  .operationalState ==
                                              'LOCKED';
                                        }

                                        return true;
                                      }

                                      return doorCubit.isCurrentlyLocked;
                                    }(),
                                    devices: state.devices,
                                    onDoorToggle: (value) {
                                      context
                                          .read<DoorLockCubit>()
                                          .toggleLock();
                                    },
                                    onAcToggle: (value) {
                                      context
                                          .read<AcControlCubit>()
                                          .togglePower();
                                    },
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}
