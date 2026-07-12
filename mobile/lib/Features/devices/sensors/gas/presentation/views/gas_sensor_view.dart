import 'package:fleexa/Features/devices/sensors/gas/presentation/views/widgets/gas_alert_section.dart';
import 'package:fleexa/Features/devices/sensors/gas/presentation/views/widgets/gas_insights_section.dart';
import 'package:fleexa/Features/devices/sensors/gas/presentation/views/widgets/gas_sensor_gauge_widget.dart';
import 'package:fleexa/Features/devices/sensors/gas/presentation/views/widgets/gas_sensor_staus_card.dart';
import 'package:fleexa/Features/devices/shared/presentation/manager/device_details_cubit.dart';
import 'package:fleexa/core/widgets/app_loading.dart';
import 'package:fleexa/core/widgets/custom_appbar.dart';
import 'package:fleexa/core/widgets/custom_refresh_indicator.dart';
import 'package:fleexa/core/widgets/error_page.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/presentation/manager/device_details_state.dart';

class GasSensorView extends StatelessWidget {
  const GasSensorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(
        title: S.of(context).gasSensor,
      ),
      body: BlocBuilder<DeviceDetailsCubit, DeviceDetailsState>(
        builder: (context, state) {
          if (state is DeviceDetailsLoading || state is DeviceDetailsInitial) {
            return const AppLoading();
          } else if (state is DeviceDetailsError) {
            return ErrorPage(
              onRetry: () {
                context
                    .read<DeviceDetailsCubit>()
                    .loadDeviceData("gas-sensor-01");
              },
              type: state.errorType,
            );
          } else if (state is DeviceDetailsLoaded) {
            final device = state.device;
            final double ppmValue =
                (device.payload['gas_level'] ?? 0).toDouble();
            return CustomRefreshIndicator(
              onRefresh: () => context
                  .read<DeviceDetailsCubit>()
                  .loadDeviceData("gas-sensor-01"),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 2,
                      ),
                      GasSensorGaugeWidget(
                        ppmValue: ppmValue,
                        status: device.operationalState,
                      ),
                      const SizedBox(
                        height: 28,
                      ),
                      GasSensorStausCard(
                        status: device.status,
                      ),
                      const SizedBox(
                        height: 32,
                      ),
                      const GasAlertsSection(),
                      const SizedBox(
                        height: 12,
                      ),
                      const GasInsightsSection(),
                      const SizedBox(
                        height: 32,
                      ),
                    ],
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
