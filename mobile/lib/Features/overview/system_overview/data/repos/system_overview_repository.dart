import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:fleexa/Features/overview/system_overview/data/models/system_overview_model.dart';
import 'package:fleexa/core/network/api_constants.dart';
import 'package:fleexa/core/network/api_service.dart';

class SystemOverviewRepository {
  final APiService apiService;

  SystemOverviewRepository(this.apiService);

 
  Future<SystemOverviewModel> getSystemOverview({
    String? period,
  }) async {
    final Response response = await apiService.get(
      ApiConstants.systemOverview,
      queryParameters: period != null ? {'period': period} : null,
    );

    final data = response.data;

    final Map<String, dynamic> jsonMap =
        data is String ? jsonDecode(data) : data;

    return SystemOverviewModel.fromJson(jsonMap);
  }


  Future<SystemOverviewModel> getAlertsChart({
    required String period,
  }) async {
    final Response response = await apiService.get(
      ApiConstants.systemOverview, 
      queryParameters: {
        'period': period,
      },
    );

    final data = response.data;

    final Map<String, dynamic> jsonMap =
        data is String ? jsonDecode(data) : data;

    return SystemOverviewModel.fromJson(jsonMap);
  }
}