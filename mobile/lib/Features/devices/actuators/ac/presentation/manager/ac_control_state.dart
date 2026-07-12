abstract class AcControlState {}

class AcControlInitial extends AcControlState {}

class AcControlUpdated extends AcControlState {
  final bool powerOn;
  final int targetTemperature;
  final String selectedMode;
  final double? timerEndTimestamp;

  AcControlUpdated({
    required this.powerOn,
    required this.targetTemperature,
    required this.selectedMode,
    this.timerEndTimestamp,
  });
}

class AcControlError extends AcControlState {
  final String message;
  AcControlError(this.message);
}
