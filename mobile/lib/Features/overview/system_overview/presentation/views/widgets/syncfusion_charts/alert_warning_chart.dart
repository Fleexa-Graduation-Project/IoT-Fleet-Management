import 'package:fleexa/Features/overview/system_overview/presentation/manager/alerts_chart_cubit/alerts_chart_cubit.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/app_strings.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../../../../../core/utils/functions/get_day_name.dart';
import '../../../../../../../core/widgets/app_error.dart';
import '../../../../../../../core/widgets/app_loading.dart';
import '../../../../../../../core/utils/constants/styles.dart';
import '../../../../data/models/alerts_chart.dart';

class AlertWarningChart extends StatelessWidget {
  const AlertWarningChart({super.key, required this.range});

  final TimeRange range;

  int _getSortOrder(String label) {
    if (label.contains(':')) {
      final parts = label.split(':');
      return (int.parse(parts[0]) * 60) + int.parse(parts[1]);
    }
    final parts = label.split(' ');
    if (parts.length == 2) {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      final month = months.indexOf(parts[0]);
      final day = int.tryParse(parts[1]) ?? 0;
      return (month * 100) + day;
    }
    return 0;
  }

  double _getMaxY(AlertsChart data) {
    final allValues = <int>[
      ...data.warning.map((e) => e.value.toInt()),
      ...data.critical.map((e) => e.value.toInt()),
    ];

    final maxValue =
        allValues.isNotEmpty ? allValues.reduce((a, b) => a > b ? a : b) : 0;

    return (maxValue == 0 ? 5 : maxValue * 1.2).ceilToDouble();
  }

  double _getInterval(double max) {
    return (max / 5).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AlertsChartCubit, AlertsChartState>(
      builder: (context, state) {
        if (state is AlertsChartLoading) {
          return const AppLoading();
        }

        if (state is AlertsChartFailure) {
          return AppError(message: state.error);
        }

        if (state is AlertsChartSuccess) {
          final data = state.data;

          final yMax = _getMaxY(data);
          final interval = _getInterval(yMax);

          final allLabels = <String>{
            ...data.warning.map((e) => e.label),
            ...data.critical.map((e) => e.label),
          }.toList();

          allLabels
              .sort((a, b) => _getSortOrder(a).compareTo(_getSortOrder(b)));

          return SfCartesianChart(
            key: ValueKey(range),
            plotAreaBorderWidth: 0,
            legend: Legend(
              isVisible: true,
              position: LegendPosition.bottom,
              iconHeight: 12,
              iconWidth: 12,
              textStyle: Styles.style12Regular.copyWith(
                color: AppColors.lightGray,
              ),
            ),
            primaryXAxis: CategoryAxis(
              labelPlacement: LabelPlacement.onTicks,
              edgeLabelPlacement: EdgeLabelPlacement.shift,
              labelIntersectAction: AxisLabelIntersectAction.rotate90,
              interval: 1,
              majorGridLines: const MajorGridLines(
                width: 1,
                color: Color(0xFF333333),
                dashArray: [5, 5],
              ),
              axisLine: const AxisLine(width: 1),
              tickPosition: TickPosition.outside,
              majorTickLines: const MajorTickLines(
                size: 12,
                color: Colors.transparent,
              ),
              labelStyle: Styles.style12Regular.copyWith(
                color: AppColors.lightGray,
              ),
            ),
            primaryYAxis: NumericAxis(
              minimum: 0,
              maximum: yMax,
              interval: interval,
              edgeLabelPlacement: EdgeLabelPlacement.shift,
              labelIntersectAction: AxisLabelIntersectAction.rotate90,
              majorGridLines: const MajorGridLines(
                width: 1,
                color: Color(0xFF333333),
                dashArray: [5, 5],
              ),
              axisLine: const AxisLine(width: 1),
              majorTickLines: const MajorTickLines(
                size: 10,
                color: Colors.transparent,
              ),
              tickPosition: TickPosition.outside,
              labelStyle: Styles.style12Regular.copyWith(
                color: AppColors.lightGray,
              ),
            ),
            series: <CartesianSeries>[
              LineSeries<String, String>(
                name: 'Anchor',
                dataSource: allLabels,
                xValueMapper: (label, _) => getDayName(label),
                yValueMapper: (label, _) => 0,
                color: Colors.transparent,
                width: 0,
                isVisibleInLegend: false,
                markerSettings: const MarkerSettings(isVisible: false),
                dataLabelSettings: const DataLabelSettings(isVisible: false),
              ),
              LineSeries(
                name: S.of(context).statusWarning,
                animationDuration: 1000,
                dataSource: data.warning,
                xValueMapper: (point, _) => getDayName(point.label),
                yValueMapper: (point, _) => point.value.toInt(),
                color: AppColors.copperOrange,
                width: 3,
                markerSettings: const MarkerSettings(
                  isVisible: true,
                  borderColor: AppColors.copperOrange,
                  color: AppColors.copperOrange,
                ),
                dataLabelSettings: DataLabelSettings(
                  isVisible: true,
                  labelAlignment: ChartDataLabelAlignment.outer,
                  textStyle: Styles.style12Regular.copyWith(
                    color: AppColors.coolGray,
                  ),
                ),
              ),
              LineSeries(
                name: S.of(context).statusCritical,
                animationDuration: 1000,
                dataSource: data.critical,
                xValueMapper: (point, _) => getDayName(point.label),
                yValueMapper: (point, _) => point.value.toInt(),
                color: AppColors.crimsonRed,
                width: 3,
                markerSettings: const MarkerSettings(
                  isVisible: true,
                  borderColor: AppColors.crimsonRed,
                  color: AppColors.crimsonRed,
                ),
                dataLabelSettings: DataLabelSettings(
                  isVisible: true,
                  labelAlignment: ChartDataLabelAlignment.outer,
                  textStyle: Styles.style12Regular.copyWith(
                    color: AppColors.coolGray,
                  ),
                ),
              ),
            ],
          );
        }

        return const SizedBox();
      },
    );
  }
}
