import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fleexa/Features/overview/system_overview/data/repos/system_overview_repository.dart';
import '../../../../../../core/errors/error_handler.dart';
import 'system_overview_state.dart';

class SystemOverviewCubit extends Cubit<SystemOverviewState> {
  final SystemOverviewRepository repository;

  SystemOverviewCubit(this.repository) : super(SystemOverviewInitial());

  Future<void> getOverview({String? period}) async {
    emit(SystemOverviewLoading());

    try {
      final data = await repository.getSystemOverview(
        period: period,
      );

      emit(SystemOverviewSuccess(data));
    } catch (e) {
      final type = ErrorHandler.getErrorType(e);
      emit(SystemOverviewFailure(error: e.toString(), errorType: type));
    }
  }
}
