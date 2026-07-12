import 'package:flutter/material.dart';

class DeviceListResponse {
  final List<DeviceModel> data;

  DeviceListResponse({required this.data});

  factory DeviceListResponse.fromJson(Map<String, dynamic> json) {
    return DeviceListResponse(
      data: (json['data'] as List?)
              ?.map((e) => DeviceModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class DeviceModel {
  final String deviceId;
  final String type;
  final String status;
  final String operationalState;
  final String health;
  final Map<String, dynamic> payload;
  final double normalUnlockDuration;

  DeviceModel({
    required this.deviceId,
    required this.type,
    required this.status,
    required this.operationalState,
    required this.health,
    required this.payload,
    this.normalUnlockDuration = 15.0,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse integers from dynamic values
    // int parseIntSafe(dynamic value) {
    //   if (value == null) return 0;
    //   if (value is int) return value;
    //   if (value is String) return int.tryParse(value) ?? 0;
    //   return 0;
    // }

    return DeviceModel(
      deviceId: json['device_id'] ?? '',
      type: json['type'] ?? '',
      status: json['status'] ?? 'OFFLINE',
      operationalState: json['operational_state'] ?? 'UNKNOWN',
      health: json['health'] ?? 'UNKNOWN',
      payload: json['payload'] ?? {},
      normalUnlockDuration:
          (json['normal_unlock_duration'] as num?)?.toDouble() ?? 15.0,
    );
  }

  Color get indicatorColor {
    // 1. Offline rule (Overrides everything)
    if (status != 'ONLINE') return Colors.red;

    // 2. Door Lock Rule (Locked = Green, Unlocked = Red)
    // if (type == 'door-actuator') {
    //   return operationalState == 'LOCKED' ? Colors.green : Colors.red;
    // }

    // 3. Gas Sensor Rule (Degraded = Orange, Safe = Green)
    if (type == 'gas-sensor') {
      return health == 'DEGRADED' ? Colors.orange : Colors.green;
    }

    // 4. Default Rule for everything else (AC, Temp, Light)
    return Colors.green;
  }

  // Helper to extract specific payload values safely
  String get displayValue {
    if (type == 'gas-sensor') return '${payload['gas_level'] ?? 0} PPM';
    if (type == 'light-sensor') return '${payload['light_level'] ?? 0} LUX';
    if (type == 'temp-sensor') return '${payload['temp'] ?? 0} °C';
    if (type == 'ac-actuator') return '${payload['target_temp'] ?? 0} °C';
    return '';
  }
}
