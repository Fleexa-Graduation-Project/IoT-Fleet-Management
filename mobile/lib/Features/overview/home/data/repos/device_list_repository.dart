import 'dart:convert';
import 'dart:developer';
import 'package:fleexa/Features/devices/shared/data/models/device_model.dart';
import 'package:fleexa/core/network/api_constants.dart';
import 'package:fleexa/core/network/api_service.dart';
import 'package:flutter/material.dart';

class DeviceListRepository {
  final APiService aPiService;

  DeviceListRepository(this.aPiService);

  Future<List<DeviceModel>> getAllDevices() async {
    try {
      final response = await aPiService.get(ApiConstants.devices);
      dynamic responseData = response.data;
      if (responseData is String) {
        responseData = jsonDecode(responseData);
      }
      final prettyJson =
          const JsonEncoder.withIndent('  ').convert(responseData);
      debugPrint("ALL DEVICES FROM SERVER:\n$prettyJson", wrapWidth: 1024);

      final result = DeviceListResponse.fromJson(responseData);
      List<DeviceModel> devices = result.data;

      bool hasMainDoor = devices.any((d) => d.deviceId == 'door-actuator-01');

      if (hasMainDoor) {
        devices.removeWhere((d) => d.deviceId == 'door-locker-01');
      }

      bool hasMainAc = devices.any((d) => d.deviceId == 'ac-actuator-01');

      if (hasMainAc) {
        devices.removeWhere((d) => d.deviceId == 'ac-curtain-01');
      }

      try {
        final doorSensor = devices.firstWhere((d) => d.type == 'door-sensor');
        final mainDoor = devices.firstWhere(
            (d) => d.type == 'door-actuator' || d.deviceId == 'door-locker-01');

        mainDoor.payload['door_physical_state'] = doorSensor.operationalState;
        mainDoor.payload['sensor_id'] = doorSensor.deviceId;

        devices.removeWhere((d) => d.type == 'door-sensor');
      } catch (e) {
        log("something went wrong while merging door sensor and locker data.");
      }

      return devices;
    } catch (e) {
      throw Exception('Failed to fetch devices: $e');
    }
  }
}
