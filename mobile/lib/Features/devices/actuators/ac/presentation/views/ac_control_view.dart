import 'package:fleexa/Features/devices/actuators/ac/presentation/views/widgets/ac_control_buttons.dart';
import 'package:fleexa/Features/devices/actuators/ac/presentation/views/widgets/ac_device_status.dart';
import 'package:fleexa/Features/devices/actuators/ac/presentation/views/widgets/ac_mode_control.dart';
import 'package:fleexa/Features/devices/actuators/ac/presentation/views/widgets/ac_temp_info.dart';
import 'package:fleexa/Features/devices/actuators/ac/presentation/views/widgets/ac_timer.dart';
import 'package:fleexa/core/router/app_router.dart';
import 'package:fleexa/core/utils/constants/app_strings.dart';
import 'package:fleexa/core/widgets/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/widgets/app_loading.dart';
import '../../../../../../core/widgets/custom_appbar.dart';
import '../../../../../../../generated/l10n.dart';
import '../../../../../../core/widgets/error_page.dart';
import '../../../../shared/presentation/manager/device_details_cubit.dart';
import '../../../../shared/presentation/manager/device_details_state.dart';
import '../manager/ac_control_cubit.dart';
import '../manager/ac_control_state.dart';

class AcControlView extends StatefulWidget {
  const AcControlView({super.key});

  @override
  State<AcControlView> createState() => _AcControlViewState();
}

class _AcControlViewState extends State<AcControlView> {
  // int controlMode = 0; // 0 = Automatic, 1 = Manual
  int threshold = 1;
  bool _isInitialized = false;
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(
        title: S.of(context).airConditioner,
        detailsPage: AppRouter.acDetails,
      ),
      body: BlocBuilder<DeviceDetailsCubit, DeviceDetailsState>(
        builder: (context, state) {
          if (state is DeviceDetailsLoading || state is DeviceDetailsInitial) {
            return const AppLoading();
          } else if (state is DeviceDetailsError) {
            return ErrorPage(
              onRetry: () {
                final currentAcId = context.read<AcControlCubit>().deviceId;
                context.read<DeviceDetailsCubit>().loadDeviceData(currentAcId);
              },
              type: state.errorType,
            );
          } else if (state is DeviceDetailsLoaded) {
            if (!_isInitialized) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context
                    .read<AcControlCubit>()
                    .initializeState(state.device.payload);
              });
              _isInitialized = true;
            }
            final insideTemp = state.device.payload['inside_temp'] ?? 24;
            final outsideTemp = state.device.payload['outside_temp'] ?? 38;
            return SafeArea(
              child: CustomRefreshIndicator(
                onRefresh: () async {
                  _isInitialized = false;
                  final currentAcId = context.read<AcControlCubit>().deviceId;
                  context
                      .read<DeviceDetailsCubit>()
                      .loadDeviceData(currentAcId);
                },
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: BlocBuilder<AcControlCubit, AcControlState>(
                        builder: (context, state) {
                          // read current values from the cubit
                          final acCubit = context.read<AcControlCubit>();
                          final powerOn = acCubit.powerOn;
                          final targetTemp = acCubit.targetTemperature;
                          final currentModeString = acCubit.selectedMode;

                          ACMode selectedMode = ACMode.values.firstWhere(
                            (m) =>
                                m.name.toUpperCase() ==
                                currentModeString.toUpperCase(),
                            orElse: () => ACMode.cooling,
                          );

                          return Column(
                            children: [
                              // ControlModeToggle(
                              //   controlMode: controlMode,
                              //   onModeChanged: (int mode) {
                              //     setState(() {
                              //       controlMode = mode;
                              //     });
                              //   },
                              // ),
                              const SizedBox(height: 16),
                              AcDeviceStatus(
                                selectedMode: selectedMode,
                                temperature: targetTemp,
                              ),
                              const SizedBox(height: 32),
                              AcControlButtons(
                                isManual: true,
                                isOn: powerOn,
                                onPowerToggle: (_) => acCubit.togglePower(),
                                onIncreaseTemp: () =>
                                    acCubit.changeTemperature(targetTemp + 1),
                                onDecreaseTemp: () =>
                                    acCubit.changeTemperature(targetTemp - 1),
                              ),
                              const SizedBox(height: 32),
                              AcModeControl(
                                acMode: selectedMode,
                                onToggle: (value) => acCubit
                                    .changeMode(value.name.toUpperCase()),
                              ),
                              const SizedBox(height: 40),
                              AcTempInfo(
                                insideTemp: insideTemp,
                                outsideTemp: outsideTemp,
                              ),
                              const SizedBox(height: 40),
                              // if (controlMode == 0)
                              const AcTimer()
                              // else
                              //   AcSmartRules(
                              //     threshold: threshold,
                              //     targetTemp: targetTemp,
                              //     onChanged: (value) {
                              //       setState(
                              //         () => threshold = value.toInt(),
                              //       );
                              //     },
                              //   ),
                            ],
                          );
                        },
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
