import 'package:fleexa/Features/overview/home/presentation/manager/devices_cubit.dart';
import 'package:fleexa/Features/overview/system_overview/presentation/manager/Energy_cubit/energy_cubit.dart';
import 'package:fleexa/Features/overview/system_overview/presentation/manager/alerts_chart_cubit/alerts_chart_cubit.dart';
import 'package:fleexa/Features/overview/system_overview/presentation/manager/system_overview_cubit/system_overview_cubit.dart';
import 'package:fleexa/Features/overview/system_overview/presentation/manager/system_overview_cubit/system_overview_state.dart';
import 'package:fleexa/Features/overview/system_overview/presentation/views/widgets/summaries_section.dart';
import 'package:fleexa/Features/overview/system_overview/presentation/views/widgets/syncfusion_charts/alert_chart_card.dart';
import 'package:fleexa/Features/overview/system_overview/presentation/views/widgets/syncfusion_charts/energy_chart_card.dart';
import 'package:fleexa/Features/overview/system_overview/presentation/views/widgets/horizontal_card_scroller.dart';
import 'package:fleexa/Features/overview/system_overview/presentation/views/widgets/system_overview_header.dart';
import 'package:fleexa/Features/overview/system_overview/presentation/views/widgets/system_status_card.dart';
import 'package:fleexa/core/widgets/custom_refresh_indicator.dart';
import 'package:fleexa/core/widgets/error_page.dart';
import 'package:fleexa/core/utils/constants/app_strings.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/app_loading.dart';
import '../../../home/presentation/manager/devices_state.dart';

class SystemOverviewView extends StatelessWidget {
  const SystemOverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<SystemOverviewCubit, SystemOverviewState>(
          builder: (context, state) {
            if (state is SystemOverviewLoading) {
              return const AppLoading();
            }

            if (state is SystemOverviewFailure) {
              return ErrorPage(
                onRetry: () {
                  context.read<SystemOverviewCubit>().getOverview();
                },
                type: state.errorType,
              );
            }

            if (state is SystemOverviewSuccess) {
              final data = state.data;

              return CustomRefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    context
                        .read<SystemOverviewCubit>()
                        .getOverview(period: TimeRange.lastWeek.apiValue),
                    context
                        .read<AlertsChartCubit>()
                        .getAlertsChart(period: TimeRange.lastWeek.apiValue),
                    context
                        .read<EnergyCubit>()
                        .getEnergy(period: TimeRange.lastWeek.apiValue),
                    context.read<DevicesCubit>().fetchDevices(),
                  ]);
                },
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SystemOverviewHeader(),
                        const SizedBox(height: 18),
                        BlocBuilder<DevicesCubit, DevicesState>(
                          builder: (context, devicesState) {
                            int totalDevices = 0;
                            int onlineDevices = 0;

                            if (devicesState is DevicesLoaded) {
                              totalDevices = devicesState.devices.length;
                              onlineDevices = devicesState.devices
                                  .where((d) => d.status == 'ONLINE')
                                  .length;
                            }

                            String displayDevices =
                                devicesState is DevicesLoaded
                                    ? "$onlineDevices / $totalDevices"
                                    : data.devicesOnline;

                            return SystemStatusCard(
                              systemStatus: data.systemStatus,
                              devicesOnline: displayDevices,
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        Text(
                          S.of(context).labelInsights,
                          style: Styles.style18Medium,
                        ),
                        const SizedBox(height: 24),
                        const HorizontalCardScroller(
                          height: 340,
                          cards: [
                            AlertChartCard(),
                            EnergyChartCard(),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text(
                          S.of(context).labelSummaries,
                          style: Styles.style18Medium,
                        ),
                        const SizedBox(height: 24),
                        const SummariesSection()
                      ],
                    ),
                  ),
                ),
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}
