import 'package:fleexa/Features/devices/shared/presentation/manager/device_telemetry_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fleexa/core/utils/constants/app_strings.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:fleexa/core/widgets/chart_time_selector.dart';
import 'package:fleexa/core/widgets/system_chart_card.dart';

import 'temp_chart.dart';

class TempInsightCard extends StatefulWidget {
  const TempInsightCard({super.key});

  @override
  State<TempInsightCard> createState() => _TempInsightCardState();
}

class _TempInsightCardState extends State<TempInsightCard> {
  TimeRange currentValue = TimeRange.lastDay;

  @override
  Widget build(BuildContext context) {
    return SystemChartCard(
      cardHeight: 300,
      title: S.of(context).tempPerformance,
      insight: TempChart(range: currentValue),
      timeFilter: ChartTimeSelector(
        currentValue: currentValue,
        onChanged: (value) {
          if (value == null) return;

          setState(() {
            currentValue = value;
          });

          context.read<DeviceTelemetryCubit>().loadTelemetry("temp-sensor-01",
              period: value.apiValue, metric: "temp");
        },
      ),
    );
  }
}
