import 'package:fleexa/Features/devices/sensors/temperature/presentation/views/widgets/circular_value_indicator.dart';
import 'package:fleexa/Features/devices/sensors/temperature/presentation/views/widgets/related_device_card.dart';
import 'package:fleexa/Features/devices/sensors/temperature/presentation/views/widgets/temp_info_summary.dart';
import 'package:fleexa/Features/devices/sensors/temperature/presentation/views/widgets/temp_stat_list.dart';
import 'package:fleexa/Features/devices/shared/presentation/manager/device_details_cubit.dart';
import 'package:fleexa/Features/devices/shared/presentation/manager/device_details_state.dart';
import 'package:fleexa/core/widgets/app_loading.dart';
import 'package:fleexa/core/widgets/custom_appbar.dart';
import 'package:fleexa/core/widgets/custom_refresh_indicator.dart';
import 'package:fleexa/core/widgets/error_page.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'widgets/temp_insight_card.dart';

class TemperatureSensorView extends StatelessWidget {
  const TemperatureSensorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(title: S.of(context).temperatureSensor),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: BlocBuilder<DeviceDetailsCubit, DeviceDetailsState>(
            builder: (context, state) {
              if (state is DeviceDetailsLoading) {
                return const AppLoading();
              }

              if (state is DeviceDetailsError) {
                return ErrorPage(
                  onRetry: () {
                    context
                        .read<DeviceDetailsCubit>()
                        .loadDeviceData("temp-sensor-01");
                  },
                  type: state.errorType,
                );
              }

              if (state is DeviceDetailsLoaded) {
                return CustomRefreshIndicator(
                  onRefresh: () => context
                      .read<DeviceDetailsCubit>()
                      .loadDeviceData("temp-sensor-01"),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 52),
                        Center(
                            child: CircularValueIndicator(
                                value: state.device.payload["temp"] ?? 0)),
                        const SizedBox(height: 40),
                        TempInfoSummary(data: state.device),
                        const SizedBox(height: 24),
                        TempStatList(data: state.device),
                        const SizedBox(height: 32),
                        const RelatedDeviceCard(),
                        const SizedBox(height: 32),
                        Text(
                          S.of(context).labelInsights,
                          style: Styles.style18Medium,
                        ),
                        const SizedBox(height: 20),
                        const TempInsightCard(),
                      ],
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
