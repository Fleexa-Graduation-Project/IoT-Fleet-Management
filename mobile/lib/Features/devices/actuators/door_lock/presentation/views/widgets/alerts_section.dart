import 'package:fleexa/Features/devices/shared/presentation/manager/device_alerts_cubit.dart';
import 'package:fleexa/Features/devices/shared/presentation/views/widgets/device_alert_card.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:fleexa/core/widgets/skelton.dart';
import 'package:fleexa/core/utils/constants/assets.dart';
import 'package:fleexa/core/utils/functions/helpers.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timelines_plus/timelines_plus.dart';

import '../../../../../../../../core/utils/constants/app_colors.dart';
import '../../../../../shared/data/models/ui_alert_model.dart';
import '../../../../../shared/presentation/manager/device_alerts_state.dart';

class AlertsSection extends StatefulWidget {
  const AlertsSection({super.key});

  @override
  State<AlertsSection> createState() => _AlertsSectionState();
}

class _AlertsSectionState extends State<AlertsSection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceAlertsCubit, DeviceAlertsState>(
      builder: (context, state) {
        if (state is DeviceAlertsLoading || state is DeviceAlertsInitial) {
          return Column(
            children: List.generate(
              2,
              (index) => const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Skelton(
                  height: 85,
                  width: double.infinity,
                ),
              ),
            ),
          );
        } else if (state is DeviceAlertsLoaded && state.alerts.isNotEmpty) {
          final displayedAlerts =
              _showAll ? state.alerts : state.alerts.take(2).toList();

          return Column(
            children: [
              const SizedBox(height: 12),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.of(context).labelAlertsAndWarnings,
                        style: Styles.style18Medium
                            .copyWith(color: AppColors.white),
                      ),
                      if (state.alerts.length > 2)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showAll = !_showAll;
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.darkMaroon,
                            padding: const EdgeInsets.only(bottom: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            _showAll ? "See Less" : "See More",
                            style: Styles.style14Regular.copyWith(
                              color: AppColors.coolGray,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.coolGray,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Timeline.tileBuilder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    theme: TimelineThemeData(
                      nodePosition: 0,
                      indicatorPosition: 0.5,
                      connectorTheme: const ConnectorThemeData(
                        thickness: 4,
                        color: AppColors.darkMaroon,
                      ),
                      indicatorTheme: const IndicatorThemeData(
                        size: 10,
                        color: AppColors.darkMaroon,
                      ),
                    ),
                    builder: TimelineTileBuilder.fromStyle(
                      contentsAlign: ContentsAlign.basic,
                      indicatorStyle: IndicatorStyle.dot,
                      itemCount: displayedAlerts.length,
                      contentsBuilder: (context, index) {
                        final apiAlert = displayedAlerts[index];
                        final uiAlert = UIAlertModel(
                          deviceId: apiAlert.deviceId,
                          title: apiAlert.title,
                          alertSeverity:
                              AlertHelper.determineAlertType(apiAlert.severity),
                          description: apiAlert.description,
                          dateTime: apiAlert.time,
                          iconPath: AppAssets.iconsDoor,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(
                              left: 8, top: 12, bottom: 12),
                          child: DeviceAlertCard(alert: uiAlert),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }
}
