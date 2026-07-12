enum DeviceStatus { online, offline }

enum DeviceFilter { all, sensors, actuators }

enum DeviceType { sensor, actuator }

enum SensorType { temperature, humidity, motion }

enum ActuatorType { doorLock, ac }

enum NotificationType { info, warning, critical }

enum AlertSeverity { warning, critical, info }

enum AlertDeviceType { doorLock, gasSensor }

enum ACMode { cooling, heating, fanOnly, dry }

enum ACControlType { manual, auto }

enum TimeRange { lastDay, lastWeek, lastMonth }

enum ErrorType { network, server, unknown }

extension TimeRangeExtension on TimeRange {
  String get apiValue {
    switch (this) {
      case TimeRange.lastDay:
        return '24h';
      case TimeRange.lastWeek:
        return '7d';
      case TimeRange.lastMonth:
        return '1m';
    }
  }
}

enum PickerMode { duration, time }

enum DialogType { deleteAccount, logout }

class AppConstants {
  static const List<String> notificationDevices = [
    'door-actuator-01',
    'gas-sensor-01',
  ];
}
