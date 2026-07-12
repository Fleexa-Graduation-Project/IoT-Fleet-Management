import 'package:fleexa/Features/devices/actuators/ac/presentation/views/widgets/ac_details_card.dart';
import 'package:fleexa/Features/devices/actuators/ac/presentation/views/widgets/ac_insights.dart';
import 'package:fleexa/Features/devices/actuators/ac/presentation/views/widgets/related_device_section.dart';
import 'package:fleexa/Features/devices/shared/presentation/manager/device_details_cubit.dart';
import 'package:fleexa/Features/devices/shared/presentation/manager/device_telemetry_cubit.dart';
import 'package:fleexa/core/widgets/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../manager/ac_control_cubit.dart';

import '../../../../../../core/widgets/custom_appbar.dart';
import '../../../../../../../generated/l10n.dart';

class AcDetailsView extends StatelessWidget {
  const AcDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(
        title: S.of(context).airConditioner,
      ),
      body: SafeArea(
        child: CustomRefreshIndicator(
          onRefresh: () async {
            final currentAcId = GetIt.instance<AcControlCubit>().deviceId;

            await Future.wait([
              context.read<DeviceDetailsCubit>().loadDeviceData(currentAcId),
              context
                  .read<DeviceTelemetryCubit>()
                  .loadTelemetry(currentAcId, metric: 'power_state'),
            ]);
          },
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AcDetailsCard(),
                    SizedBox(height: 32),
                    RelatedDeviceSection(),
                    SizedBox(height: 32),
                    AcInsights(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
