import 'package:fleexa/Features/overview/system_overview/presentation/manager/Energy_cubit/energy_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fleexa/Features/overview/system_overview/data/repos/system_overview_repository.dart';

import '../../../../../../core/errors/error_handler.dart';

class EnergyCubit extends Cubit<EnergyState> {
  final SystemOverviewRepository repository;

  EnergyCubit(this.repository) : super(EnergyInitial());

  Future<void> getEnergy({String? period}) async {
    emit(EnergyLoading());

    try {
      final data = await repository.getSystemOverview(period: period);

      emit(EnergySuccess(data.energyConsumption));
    } catch (e) {
      final type = ErrorHandler.getErrorType(e);
      emit(EnergyFailure(error: e.toString(), errorType: type));
    }
  }
}
