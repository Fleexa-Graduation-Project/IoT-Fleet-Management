import '../../../../../core/utils/constants/app_strings.dart';
import '../../data/models/device_model.dart';

abstract class DeviceDetailsState {}

class DeviceDetailsInitial extends DeviceDetailsState {}

class DeviceDetailsLoading extends DeviceDetailsState {}

class DeviceDetailsError extends DeviceDetailsState {
  final String message;
  final ErrorType errorType;
  DeviceDetailsError({required this.message, required this.errorType});
}

class DeviceDetailsLoaded extends DeviceDetailsState {
  final DeviceModel device;
  DeviceDetailsLoaded({required this.device});
}
