import 'dart:developer';

import 'package:fleexa/Features/devices/shared/data/repos/device_details_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/error_handler.dart';
import '../../data/models/device_model.dart';
import 'device_details_state.dart';

class DeviceDetailsCubit extends Cubit<DeviceDetailsState> {
  final DeviceDetailsRepository repository;

  DeviceDetailsCubit(this.repository) : super(DeviceDetailsInitial());

  Future<void> loadDeviceData(String deviceId, {String period = '7d'}) async {
    emit(DeviceDetailsLoading());
    try {
      final device = await repository.getDeviceDetails(deviceId);

      if (!isClosed) {
        emit(DeviceDetailsLoaded(device: device));
      }
    } catch (e) {
      if (!isClosed) {
        final type = ErrorHandler.getErrorType(e);
        emit(DeviceDetailsError(errorType: type, message: e.toString()));
      }
    }
  }

  Future<void> setNormalUnlockDuration(String deviceId, int minutes) async {
    if (state is DeviceDetailsLoaded) {
      final currentState = state as DeviceDetailsLoaded;
      final currentDevice = currentState.device;

      final updatedPayload = Map<String, dynamic>.from(currentDevice.payload);
      updatedPayload['normal_unlock_duration'] = minutes;

      final updatedDevice = DeviceModel(
        deviceId: currentDevice.deviceId,
        type: currentDevice.type,
        status: currentDevice.status,
        operationalState: currentDevice.operationalState,
        health: currentDevice.health,
        payload: currentDevice.payload, 
        normalUnlockDuration: minutes.toDouble(),
      );

      emit(DeviceDetailsLoaded(device: updatedDevice));

      try {
        await repository.updateDevicePreferences(deviceId, minutes.toDouble());
        log("Backend preferences updated successfully with $minutes minutes");
      } catch (e) {
        log("Failed to update backend preferences: $e");
      }
    }
  }
}
