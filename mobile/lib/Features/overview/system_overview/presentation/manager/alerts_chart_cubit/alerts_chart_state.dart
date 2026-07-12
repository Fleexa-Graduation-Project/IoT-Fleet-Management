part of 'alerts_chart_cubit.dart';

@immutable
sealed class AlertsChartState {}

final class AlertsChartInitial extends AlertsChartState {}

final class AlertsChartLoading extends AlertsChartState {}

final class AlertsChartSuccess extends AlertsChartState {
  final AlertsChart data;

  AlertsChartSuccess(this.data);
}

final class AlertsChartFailure extends AlertsChartState {
  final String error;
  final ErrorType errorType;
  AlertsChartFailure({required this.error, required this.errorType});
}
