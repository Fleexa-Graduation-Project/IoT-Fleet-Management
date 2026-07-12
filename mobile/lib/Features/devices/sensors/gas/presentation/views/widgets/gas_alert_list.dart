import 'package:fleexa/Features/devices/shared/data/models/ui_alert_model.dart';
import 'package:fleexa/Features/devices/shared/presentation/views/widgets/device_alert_card.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/assets.dart';
import 'package:fleexa/core/utils/functions/helpers.dart';
import 'package:flutter/material.dart';
import 'package:timelines_plus/timelines_plus.dart';

import '../../../../../shared/data/models/alert_model.dart';

class GasAlertList extends StatelessWidget {
  const GasAlertList({super.key, required this.alerts});

  final List<AlertModel> alerts;

  @override
  Widget build(BuildContext context) {
    final List<UIAlertModel> uiAlerts = alerts.map((apiAlert) {
      return UIAlertModel(
        deviceId: apiAlert.deviceId,
        title: apiAlert.title,
        alertSeverity: AlertHelper.determineAlertType(apiAlert.severity),
        description: apiAlert.description,
        dateTime: apiAlert.time,
        iconPath: AppAssets.iconsFire,
      );
    }).toList();
    return Timeline.tileBuilder(
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
        itemCount: uiAlerts.length,
        contentsBuilder: (context, index) {
          final alert = uiAlerts[index];
          return Padding(
            padding: const EdgeInsets.only(
              left: 8,
              top: 12,
              bottom: 12,
            ),
            child: DeviceAlertCard(alert: alert),
          );
        },
      ),
    );
  }
}
