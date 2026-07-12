import 'package:fleexa/Features/devices/shared/data/models/device_model.dart';
import 'package:fleexa/core/utils/constants/app_strings.dart';

abstract class DevicesState {}

class DevicesInitial extends DevicesState {}

class DevicesLoading extends DevicesState {}

class DevicesError extends DevicesState {
  final String message;
  final ErrorType errorType;
  DevicesError({required this.errorType, this.message = ""});
}

class DevicesLoaded extends DevicesState {
  final List<DeviceModel> devices;
  final DeviceFilter currentFilter;

  DevicesLoaded({
    required this.devices,
    required this.currentFilter,
  });
}
