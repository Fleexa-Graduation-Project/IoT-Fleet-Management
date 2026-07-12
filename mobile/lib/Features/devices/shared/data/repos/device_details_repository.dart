import 'dart:convert';

import 'package:fleexa/Features/devices/shared/data/models/alert_model.dart';
import 'package:fleexa/Features/devices/shared/data/models/device_command_model.dart';
import 'package:fleexa/Features/devices/shared/data/models/device_model.dart';
import 'package:fleexa/Features/devices/shared/data/models/telemetry_model.dart';
import 'package:fleexa/core/network/api_constants.dart';
import 'package:fleexa/core/network/api_service.dart';

class DeviceDetailsRepository {
  final APiService apiService;

  DeviceDetailsRepository(this.apiService);

  // 1. Fetches the Gauge Data & Live Status
  Future<DeviceModel> getDeviceDetails(String deviceId) async {
    try {
      final response =
          await apiService.get(ApiConstants.deviceDetails(deviceId));

      dynamic responseData = response.data;
      if (responseData is String) responseData = jsonDecode(responseData);

      return DeviceModel.fromJson(responseData);
    } catch (e) {
      throw Exception('Failed to fetch details for $deviceId: $e');
    }
  }

  // 2. Fetches the Insights Chart Data
  Future<TelemetryModel> getDeviceTelemetry(
      String deviceId, String period, String metric) async {
    try {
      final response = await apiService.get(
        ApiConstants.deviceTelemetry(deviceId),
        queryParameters: {
          "period": period,
          "metric": metric,
        },
      );

      dynamic responseData = response.data;
      if (responseData is String) responseData = jsonDecode(responseData);

      return TelemetryModel.fromJson(responseData);
    } catch (e) {
      throw Exception('Failed to fetch telemetry for $deviceId: $e');
    }
  }

  // 3. Fetches the Alerts Data
  Future<List<AlertModel>> getDeviceAlerts(String deviceId) async {
    try {
      final response =
          await apiService.get(ApiConstants.deviceAlerts(deviceId));

      dynamic responseData = response.data;
      if (responseData is String) responseData = jsonDecode(responseData);

      final List dataList = responseData['data'] ?? [];
      return dataList.map((item) => AlertModel.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> sendDeviceCommand(
      {required String deviceId,
      required String action,
      Map<String, dynamic>? parameters}) async {
    final String uniqeReqId = 'cmd-${DateTime.now().millisecondsSinceEpoch}';

    final command = DeviceCommandModel(
      requestId: uniqeReqId,
      action: action,
      parameters: parameters ?? {},
    );

    await apiService.post(
      ApiConstants.deviceCommands(deviceId),
      data: command.toJson(),
    );
  }

  Future<void> updateDevicePreferences(
      String deviceId, double normalDuration) async {
    try {
      await apiService.put(
        ApiConstants.devicePreferences(deviceId),
        data: {
          "normal_unlock_duration": normalDuration,
        },
      );
    } catch (e) {
      throw Exception('Failed to update device preferences: $e');
    }
  }
}
