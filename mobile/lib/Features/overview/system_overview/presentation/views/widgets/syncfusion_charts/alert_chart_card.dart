import 'package:fleexa/Features/overview/system_overview/presentation/manager/alerts_chart_cubit/alerts_chart_cubit.dart';
import 'package:fleexa/core/widgets/chart_time_selector.dart';
import 'package:fleexa/core/utils/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../generated/l10n.dart';
import 'alert_warning_chart.dart';
import '../../../../../../../core/widgets/system_chart_card.dart';

class AlertChartCard extends StatefulWidget {
  const AlertChartCard({super.key});

  @override
  State<AlertChartCard> createState() => _AlertChartCardState();
}

class _AlertChartCardState extends State<AlertChartCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  TimeRange currentValue = TimeRange.lastWeek;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SystemChartCard(
      title: S.of(context).labelAlertsAndWarnings,
      insight: AlertWarningChart(range: currentValue),
      timeFilter: ChartTimeSelector(
        currentValue: currentValue,
        onChanged: (value) {
          if (value == null) return;

          setState(() {
            currentValue = value;
          });

          context.read<AlertsChartCubit>().getAlertsChart(
                period: value.apiValue,
              );
        },
      ),
    );
  }
}
