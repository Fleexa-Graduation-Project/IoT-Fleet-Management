import 'package:fleexa/Features/devices/shared/data/repos/device_details_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/error_handler.dart';
import 'device_telemetry_state.dart';

class DeviceTelemetryCubit extends Cubit<DeviceTelemetryState> {
  final DeviceDetailsRepository repository;

  DeviceTelemetryCubit(this.repository) : super(DeviceTelemetryInitial());

  Future<void> loadTelemetry(String deviceId,
      {required String metric, String period = '24h'}) async {
    emit(DeviceTelemetryLoading());
    try {
      final telemetry =
          await repository.getDeviceTelemetry(deviceId, period, metric);
      emit(
        DeviceTelemetryLoaded(
          telemetry: telemetry,
          currentPeriod: period,
        ),
      );
    } catch (e) {
      final type = ErrorHandler.getErrorType(e);
      emit(DeviceTelemetryError(errorType: type, message: e.toString()));
    }
  }
}
