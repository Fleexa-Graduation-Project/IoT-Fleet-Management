abstract class DoorLockState {}

class DoorLockInitial extends DoorLockState {}

class DoorLockUpdated extends DoorLockState {
  final bool isLocked;
  DoorLockUpdated(this.isLocked);
}

class DoorLockError extends DoorLockState {
  final String message;
  DoorLockError(this.message);
}
