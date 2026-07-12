class DeviceCommandModel {
  final String requestId;
  final String action;
  final Map<String, dynamic> parameters;

  DeviceCommandModel({
    required this.requestId,
    required this.action,
    this.parameters = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'action': action,
      'parameters': parameters,
    };
  }
}
