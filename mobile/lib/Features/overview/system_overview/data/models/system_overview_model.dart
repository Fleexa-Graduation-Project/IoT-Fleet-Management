import 'package:fleexa/Features/overview/system_overview/data/models/alerts_chart.dart';
import 'package:fleexa/Features/overview/system_overview/data/models/chart_point.dart';

class SystemOverviewModel {
  final String systemStatus;
  final String devicesOnline;
  final AlertsChart alertsChart;
  final List<ChartPoint> energyConsumption;

  SystemOverviewModel({
    required this.systemStatus,
    required this.devicesOnline,
    required this.alertsChart,
    required this.energyConsumption,
  });

  factory SystemOverviewModel.fromJson(Map<String, dynamic> json) {
    return SystemOverviewModel(
      systemStatus: json['system_status'] ?? '',
      devicesOnline: json['devices_online'] ?? '',
      alertsChart: AlertsChart.fromJson(json['alerts_chart'] ?? {}),
      energyConsumption: (json['energy_consumption'] as List<dynamic>? ?? [])
          .map((e) => ChartPoint.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'system_status': systemStatus,
      'devices_online': devicesOnline,
      'alerts_chart': alertsChart.toJson(),
      'energy_consumption':
          energyConsumption.map((e) => e.toJson()).toList(),
    };
  }
}