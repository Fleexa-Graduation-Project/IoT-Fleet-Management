import 'package:fleexa/Features/devices/shared/data/models/telemetry_model.dart';

import '../../../../../core/utils/constants/app_strings.dart';

abstract class DeviceTelemetryState {}

class DeviceTelemetryInitial extends DeviceTelemetryState {}

class DeviceTelemetryLoading extends DeviceTelemetryState {}

class DeviceTelemetryError extends DeviceTelemetryState {
  final String message;
  final ErrorType errorType;
  DeviceTelemetryError({required this.message, required this.errorType});
}

class DeviceTelemetryLoaded extends DeviceTelemetryState {
  final TelemetryModel telemetry;
  final String currentPeriod;

  DeviceTelemetryLoaded({
    required this.telemetry,
    required this.currentPeriod,
  });
}
