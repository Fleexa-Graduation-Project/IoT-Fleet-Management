import 'package:fleexa/Features/overview/system_overview/data/models/system_overview_model.dart';

import '../../../../../../core/utils/constants/app_strings.dart';

abstract class SystemOverviewState {}

class SystemOverviewInitial extends SystemOverviewState {}

class SystemOverviewLoading extends SystemOverviewState {}

class SystemOverviewSuccess extends SystemOverviewState {
  final SystemOverviewModel data;

  SystemOverviewSuccess(this.data);
}

class SystemOverviewFailure extends SystemOverviewState {
  final String error;
  final ErrorType errorType;
  SystemOverviewFailure({required this.error, required this.errorType});
}
