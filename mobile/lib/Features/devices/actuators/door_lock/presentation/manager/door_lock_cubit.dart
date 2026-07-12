import 'package:fleexa/Features/devices/actuators/door_lock/presentation/manager/door_lock_state.dart';
import 'package:fleexa/Features/devices/shared/data/repos/device_details_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer';

class DoorLockCubit extends Cubit<DoorLockState> {
  final DeviceDetailsRepository repository;
  String deviceId;

  bool isCurrentlyLocked = true;

  DoorLockCubit({required this.repository, required this.deviceId})
      : super(DoorLockInitial());

  void initializeState(bool isLockedFromApi) {
    isCurrentlyLocked = isLockedFromApi;
    emit(DoorLockUpdated(isCurrentlyLocked));
  }

  Future<void> toggleLock() async {
    log("Button Pressed! Current State: $isCurrentlyLocked");
    final bool previousState = isCurrentlyLocked;

    isCurrentlyLocked = !isCurrentlyLocked;
    emit(DoorLockUpdated(isCurrentlyLocked));

    final String actionCommand = isCurrentlyLocked ? "LOCK" : "UNLOCK";
    log("Sending Command: $actionCommand for Device: $deviceId");

    try {
      await repository.sendDeviceCommand(
        deviceId: deviceId,
        action: actionCommand,
      );
      log("Command Sent Successfully!");
    } catch (e) {
      log("ERROR in sendDeviceCommand: $e");
      isCurrentlyLocked = previousState;
      emit(DoorLockError(
          'Failed to $actionCommand the door. Check your connection.'));
      emit(DoorLockUpdated(isCurrentlyLocked));
    }
  }
}
