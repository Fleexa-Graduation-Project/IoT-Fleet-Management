import '../../../../../core/utils/constants/app_strings.dart';
import '../../data/models/alert_model.dart';

abstract class DeviceAlertsState {}

class DeviceAlertsInitial extends DeviceAlertsState {}

class DeviceAlertsLoading extends DeviceAlertsState {}

class DeviceAlertsError extends DeviceAlertsState {
  final String message;
  final ErrorType errorType;
  DeviceAlertsError({required this.message, required this.errorType});
}

class DeviceAlertsLoaded extends DeviceAlertsState {
  final List<AlertModel> alerts;
  DeviceAlertsLoaded({required this.alerts});
}
