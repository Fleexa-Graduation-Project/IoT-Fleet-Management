import 'package:fleexa/core/utils/constants/app_strings.dart';
import 'package:intl/intl.dart';

class AlertHelper {
  static AlertSeverity determineAlertType(String severity) {
    if (severity.toUpperCase() == 'CRITICAL') {
      return AlertSeverity.critical;
    }
    return AlertSeverity.warning;
  }

  static String formatTimeForUI(DateTime time) {
    return DateFormat("hh:mm a").format(time);
  }
}
