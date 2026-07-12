class DeviceStatusModel {
  final String status;
  final String description;
  final bool isConnected;
  const DeviceStatusModel({
    required this.status,
    required this.description,
    this.isConnected=false,
  });

}