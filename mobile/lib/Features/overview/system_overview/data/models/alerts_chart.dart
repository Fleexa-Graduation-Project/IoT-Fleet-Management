import 'package:fleexa/Features/overview/system_overview/data/models/chart_point.dart';

class AlertsChart {
  final List<ChartPoint> warning;
  final List<ChartPoint> critical;

  AlertsChart({
    required this.warning,
    required this.critical,
  });

  factory AlertsChart.fromJson(Map<String, dynamic> json) {
    return AlertsChart(
      warning: (json['warning'] as List<dynamic>? ?? [])
          .map((e) => ChartPoint.fromJson(e))
          .toList(),
      critical: (json['critical'] as List<dynamic>? ?? [])
          .map((e) => ChartPoint.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'warning': warning.map((e) => e.toJson()).toList(),
      'critical': critical.map((e) => e.toJson()).toList(),
    };
  }
}