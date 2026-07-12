import 'dart:convert';

import 'package:fleexa/Features/devices/shared/data/models/alert_model.dart';
import 'package:fleexa/core/network/api_constants.dart';
import 'package:fleexa/core/network/api_service.dart';
import 'package:flutter/material.dart';

class NotificationsRepository {
  final APiService apiService;

  NotificationsRepository(this.apiService);

  Future<({List<AlertModel> alerts, String? nextCursor})> getAllSystemAlerts({
    int limit = 20,
    String? beforeCursor,
  }) async {
    try {
      final queryParams = {
        'limit': limit,
        if (beforeCursor != null) 'before': beforeCursor,
      };

      final response = await apiService.get(
        ApiConstants.allAlerts,
        queryParameters: queryParams,
      );

      dynamic responseData = response.data;
      if (responseData is String) responseData = jsonDecode(responseData);
      final prettyJson =
          const JsonEncoder.withIndent('  ').convert(responseData);
      debugPrint("ALL ALERTS FROM SERVER:\n$prettyJson", wrapWidth: 1024);
      final List dataList = responseData['data'] ?? [];
      final String? nextCursor = responseData['next_cursor']?.toString();

      final List<AlertModel> alerts = dataList
          .map((json) => AlertModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return (alerts: alerts, nextCursor: nextCursor);
    } catch (e) {
      throw Exception('Failed to fetch system notifications: $e');
    }
  }

  Future<void> markAlertAsRead(String alertId) async {
    try {
      await apiService.put(
        ApiConstants.markAlertRead,
        data: {
          "alert_id": alertId,
        },
      );
    } catch (e) {
      throw Exception('Failed to mark alert $alertId as read: $e');
    }
  }
}
