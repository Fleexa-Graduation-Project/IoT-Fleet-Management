import 'package:fleexa/Features/overview/system_overview/data/models/chart_point.dart';

import '../../../../../../core/utils/constants/app_strings.dart';

abstract class EnergyState {}

class EnergyInitial extends EnergyState {}

class EnergyLoading extends EnergyState {}

class EnergySuccess extends EnergyState {
  final List<ChartPoint> data;

  EnergySuccess(this.data);
}

class EnergyFailure extends EnergyState {
  final String error;
  final ErrorType errorType;
  EnergyFailure({required this.error, required this.errorType});
}
