import 'package:fleexa/Features/devices/sensors/gas/presentation/views/widgets/gas_alert_list.dart';
import 'package:fleexa/Features/devices/shared/presentation/manager/device_alerts_cubit.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/widgets/skelton.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/presentation/manager/device_alerts_state.dart';

class GasAlertsSection extends StatefulWidget {
  const GasAlertsSection({super.key});

  @override
  State<GasAlertsSection> createState() => _GasAlertsSectionState();
}

class _GasAlertsSectionState extends State<GasAlertsSection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceAlertsCubit, DeviceAlertsState>(
      builder: (context, state) {
        if (state is DeviceAlertsLoading || state is DeviceAlertsInitial) {
          return Column(
            children: List.generate(
              2,
              (index) => const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Skelton(height: 85, width: double.infinity),
              ),
            ),
          );
        } else if (state is DeviceAlertsLoaded && state.alerts.isNotEmpty) {
          final displayedAlerts =
              _showAll ? state.alerts : state.alerts.take(2).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    S.of(context).labelAlertsAndWarnings,
                    style: Styles.style18Medium,
                  ),
                  if (state.alerts.length > 2)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showAll = !_showAll;
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        _showAll ? "See Less" : "See More",
                        style: Styles.style14Regular.copyWith(
                          color: AppColors.coolGray,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.coolGray,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              GasAlertList(alerts: displayedAlerts),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }
}
