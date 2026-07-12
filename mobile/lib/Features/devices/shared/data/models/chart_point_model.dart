class ChartPointModel {
  final String label;
  final double value;

  ChartPointModel({required this.label, required this.value});

  factory ChartPointModel.fromJson(Map<String, dynamic> json) {
    return ChartPointModel(
      label: json['label'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
    );
  }
}
