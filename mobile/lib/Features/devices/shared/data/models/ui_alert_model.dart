import 'package:fleexa/Features/devices/shared/data/models/alert_model.dart';
import 'package:fleexa/core/utils/constants/app_strings.dart';
import 'package:fleexa/core/utils/constants/assets.dart';

class UIAlertModel {
  final String deviceId;
  final String title;
  final String alertId;
  final String description;
  final DateTime dateTime;
  final String iconPath;
  final AlertSeverity alertSeverity;
  final bool isRead;

  const UIAlertModel({
    required this.deviceId,
    required this.title,
    required this.alertSeverity,
    required this.description,
    required this.dateTime,
    required this.iconPath,
    this.isRead = false,
    this.alertId = '',
  });

  factory UIAlertModel.fromAlertModel(AlertModel apiModel) {
    AlertSeverity mappedType;
    final String serverSeverity = apiModel.severity.toUpperCase();
    if (serverSeverity == 'CRITICAL') {
      mappedType = AlertSeverity.critical;
    } else if (serverSeverity == 'INFO') {
      mappedType = AlertSeverity.info;
    } else {
      mappedType = AlertSeverity.warning;
    }

    String icon = AppAssets.iconsInfo;
    if (apiModel.deviceType == 'gas-sensor') {
      icon = AppAssets.iconsFire;
    } else if (apiModel.deviceType == 'door-sensor') {
      icon = AppAssets.iconsDoor;
    } else {
      icon = AppAssets.iconsAc;
    }
    return UIAlertModel(
      deviceId: apiModel.deviceId,
      title: apiModel.title,
      description: apiModel.description,
      dateTime: apiModel.time,
      iconPath: icon,
      alertSeverity: mappedType,
      isRead: apiModel.isRead,
      alertId: apiModel.alertId,
    );
  }

  UIAlertModel copyWith({bool? isRead}) {
    return UIAlertModel(
      deviceId: deviceId,
      title: title,
      description: description,
      dateTime: dateTime,
      iconPath: iconPath,
      alertSeverity: alertSeverity,
      isRead: isRead ?? this.isRead,
      alertId: alertId,
    );
  }
}
