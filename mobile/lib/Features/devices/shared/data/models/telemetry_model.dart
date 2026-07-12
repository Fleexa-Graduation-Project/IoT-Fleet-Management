import 'chart_point_model.dart';

class TelemetryModel {
  final String period;
  final List<ChartPointModel> data;
  final double chartMax;

  TelemetryModel({
    required this.period,
    required this.data,
    required this.chartMax,
  });

  factory TelemetryModel.fromJson(Map<String, dynamic> json) {
    return TelemetryModel(
      period: json['period'] ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => ChartPointModel.fromJson(item))
              .toList() ??
          [],
      chartMax: (json['chart_max'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
