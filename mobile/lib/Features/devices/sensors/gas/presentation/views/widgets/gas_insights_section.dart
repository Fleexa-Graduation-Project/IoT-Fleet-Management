import 'package:fleexa/Features/devices/sensors/gas/presentation/views/widgets/gas_sensor_chart.dart';
import 'package:fleexa/Features/devices/shared/presentation/manager/device_telemetry_cubit.dart';
import 'package:fleexa/Features/devices/shared/presentation/manager/device_telemetry_state.dart';
import 'package:fleexa/core/widgets/app_error.dart';
import 'package:fleexa/core/widgets/app_loading.dart';
import 'package:fleexa/core/widgets/chart_time_selector.dart';
import 'package:fleexa/core/widgets/system_chart_card.dart';
import 'package:fleexa/core/utils/constants/app_strings.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GasInsightsSection extends StatefulWidget {
  const GasInsightsSection({super.key});

  @override
  State<GasInsightsSection> createState() => _GasInsightsSectionState();
}

class _GasInsightsSectionState extends State<GasInsightsSection> {
  TimeRange currentValue = TimeRange.lastDay;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).labelInsights,
          style: Styles.style18Medium,
        ),
        const SizedBox(height: 20),
        SystemChartCard(
          title: S.of(context).gasLevel,
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
                context.read<DeviceTelemetryCubit>().loadTelemetry(
                    'gas-sensor-01',
                    period: apiPeriod,
                    metric: 'gas_level');
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
                return GasSensorChart(
                  data: state.telemetry.data,
                  periodKey: state.currentPeriod,
                  maxValue: state.telemetry.chartMax,
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }
}
