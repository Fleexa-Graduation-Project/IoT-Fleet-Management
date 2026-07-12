import 'package:fleexa/Features/overview/system_overview/presentation/manager/Energy_cubit/energy_cubit.dart';
import 'package:fleexa/Features/overview/system_overview/presentation/manager/Energy_cubit/energy_state.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syncfusion_flutter_charts/charts.dart' hide ChartPoint;

import '../../../../../../../core/utils/functions/get_day_name.dart';
import '../../../../../../../core/widgets/app_error.dart';
import '../../../../../../../core/widgets/app_loading.dart';
import '../../../../../../../core/utils/constants/styles.dart';
import '../../../../data/models/chart_point.dart';

class EnergyConsumptionChart extends StatelessWidget {
  const EnergyConsumptionChart({super.key, required this.range});

  final TimeRange range;

  double _getMaxY(List<ChartPoint> data) {
    final maxValue = data.isNotEmpty
        ? data.map((e) => e.value).reduce((a, b) => a > b ? a : b)
        : 0;

    return (maxValue == 0 ? 10 : maxValue * 1.2).ceilToDouble();
  }

  double _getInterval(double max) {
    return (max / 5).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EnergyCubit, EnergyState>(
      builder: (context, state) {
        if (state is EnergyLoading) {
          return const AppLoading();
        }

        if (state is EnergyFailure) {
          return AppError(message: state.error);
        }

        if (state is EnergySuccess) {
          final List<ChartPoint> data = state.data;

          final yMax = _getMaxY(data);
          final interval = _getInterval(yMax);

          return SfCartesianChart(
            key: ValueKey(range),
            plotAreaBorderWidth: 0,
            primaryXAxis: CategoryAxis(
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
              labelIntersectAction: AxisLabelIntersectAction.rotate90,
              axisLine: const AxisLine(width: 1),
              tickPosition: TickPosition.outside,
              majorTickLines: const MajorTickLines(
                size: 12,
                color: Colors.transparent,
              ),
              majorGridLines: const MajorGridLines(
                width: 1,
                color: Color(0xFF333333),
                dashArray: [5, 5],
              ),
              labelStyle: Styles.style12Regular.copyWith(
                color: AppColors.lightGray,
              ),
            ),
            series: <CartesianSeries>[
              ColumnSeries<ChartPoint, String>(
                dataSource: data,
                xValueMapper: (point, _) => getDayName(point.label),
                yValueMapper: (point, _) => point.value,
                color: AppColors.wineRed,
                width: range == TimeRange.lastMonth ? 0.4 : 0.6,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4.r),
                  topRight: Radius.circular(4.r),
                ),
                isTrackVisible: true,
                trackColor: AppColors.darkGray,
                trackPadding: 0,
                animationDuration: 1000,
                dataLabelSettings: DataLabelSettings(
                  isVisible: true,
                  labelPosition: ChartDataLabelPosition.outside,
                  textStyle: Styles.style10Regular.copyWith(
                    color: AppColors.lightGray,
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
