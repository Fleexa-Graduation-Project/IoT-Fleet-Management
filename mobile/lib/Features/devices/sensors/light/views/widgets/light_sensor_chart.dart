import 'package:fleexa/Features/devices/shared/data/models/chart_point_model.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';

import '../../../../../../core/utils/functions/get_day_name.dart';

class LightSensorChart extends StatelessWidget {
  const LightSensorChart({
    super.key,
    required this.data,
    required this.periodKey,
    required this.maxValue,
  });

  final List<ChartPointModel> data;
  final String periodKey;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final double dataMax = data.isNotEmpty
        ? data.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble()
        : 0.0;

    final double dynamicMax = dataMax == 0 ? 5.0 : (dataMax * 1.2);

    double interval = (dynamicMax / 5).ceilToDouble();
    if (interval <= 0) interval = 1.0;

    return SfCartesianChart(
      key: ValueKey(periodKey),

      legend: Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        iconHeight: 12,
        iconWidth: 12,
        textStyle: Styles.style12Regular.copyWith(color: AppColors.lightGray),
      ),

      plotAreaBorderWidth: 0,
      plotAreaBorderColor: Colors.transparent,

      /// X Axis
      primaryXAxis: CategoryAxis(
        interval: 1,
        labelIntersectAction: AxisLabelIntersectAction.rotate90,
        labelAlignment: LabelAlignment.center,
        placeLabelsNearAxisLine: false,
        labelStyle: Styles.style10Regular.copyWith(color: AppColors.coolGray),
        axisLine: const AxisLine(width: 1, color: AppColors.coolGray),
        axisLabelFormatter: (args) {
          return ChartAxisLabel(args.text, args.textStyle);
        },
        majorGridLines: MajorGridLines(
          width: 1,
          color: AppColors.white.withOpacity(0.05),
          dashArray: const [5, 5],
        ),
        majorTickLines: const MajorTickLines(size: 0),
      ),

      /// Y Axis
      primaryYAxis: NumericAxis(
        minimum: 0,
        maximum: dynamicMax,
        interval: interval,
        majorTickLines: const MajorTickLines(size: 0),
        majorGridLines: MajorGridLines(
          width: 1,
          color: AppColors.white.withOpacity(0.05),
          dashArray: const [5, 5],
        ),
        labelStyle: Styles.style12Regular.copyWith(color: AppColors.coolGray),
        axisLine: const AxisLine(width: 1, color: AppColors.coolGray),
        tickPosition: TickPosition.inside,
      ),

      /// Series
      series: <CartesianSeries>[
        LineSeries<ChartPointModel, String>(
          dataSource: data,
          name: S.of(context).unitLuxText,
          xValueMapper: (point, _) => getDayName(point.label),
          yValueMapper: (point, _) => point.value,
          color: AppColors.crimsonRed,
          width: 2,
          markerSettings: const MarkerSettings(
            isVisible: true,
            height: 4,
            width: 4,
            color: AppColors.crimsonRed,
            borderColor: AppColors.crimsonRed,
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
}
