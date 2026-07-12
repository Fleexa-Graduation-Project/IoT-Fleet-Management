import 'package:fleexa/core/widgets/system_chart_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/widgets/chart_time_selector.dart';
import '../../../../../../../../core/utils/constants/app_strings.dart';
import '../../../../../../../../generated/l10n.dart';
import '../../../../../../../core/widgets/app_error.dart';
import '../../../../../../../core/widgets/app_loading.dart';
import '../../../../../shared/presentation/manager/device_telemetry_cubit.dart';
import '../../../../../shared/presentation/manager/device_telemetry_state.dart';
import 'package:get_it/get_it.dart';
import '../../../../../actuators/ac/presentation/manager/ac_control_cubit.dart';
import 'usage_chart.dart';

class AcInsightUsage extends StatefulWidget {
  const AcInsightUsage({super.key});

  @override
  State<AcInsightUsage> createState() => _AcInsightUsageState();
}

class _AcInsightUsageState extends State<AcInsightUsage> {
  TimeRange currentValue = TimeRange.lastDay;
  @override
  Widget build(BuildContext context) {
    return SystemChartCard(
      cardHeight: 350,
      title: S.of(context).AirConditionerUsage,
      timeFilter: ChartTimeSelector(
        currentValue: currentValue,
        onChanged: (value) {
          if (value != null && value != currentValue) {
            setState(() {
              currentValue = value;
            });
            String apiPeriod = '24h';
            if (value == TimeRange.lastWeek) apiPeriod = '7d';
            if (value == TimeRange.lastMonth) apiPeriod = '1m';
            final currentAcId = GetIt.instance<AcControlCubit>().deviceId;

            context.read<DeviceTelemetryCubit>().loadTelemetry(currentAcId,
                period: apiPeriod, metric: 'power_state');
          }
        },
      ),
      insight: BlocBuilder<DeviceTelemetryCubit, DeviceTelemetryState>(
        builder: (context, state) {
          if (state is DeviceTelemetryLoading ||
              state is DeviceTelemetryInitial) {
            return const SizedBox(
              height: 200,
              child: AppLoading(),
            );
          } else if (state is DeviceTelemetryError) {
            return SizedBox(
              height: 200,
              child: AppError(message: state.message),
            );
          } else if (state is DeviceTelemetryLoaded) {
            return UsageChart(
              data: state.telemetry.data,
              periodKey: state.currentPeriod,
              maxValue: state.telemetry.chartMax,
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}
