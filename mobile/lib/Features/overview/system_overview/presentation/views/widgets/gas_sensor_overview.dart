import 'package:fleexa/Features/devices/shared/data/models/device_model.dart';
import 'package:fleexa/core/widgets/custom_container.dart';
import 'package:fleexa/Features/overview/system_overview/presentation/views/widgets/gas_sensor_gauge.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';

class GasSensorOverview extends StatelessWidget {
  const GasSensorOverview({super.key, required this.gasDevice});

  final DeviceModel gasDevice;

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SAFE':
      case 'NORMAL':
        return AppColors.emeraldGreen;
      case 'WARNING':
        return AppColors.copperOrange;
      case 'CRITICAL':
      case 'DANGER':
        return AppColors.burgundy;
      default:
        return AppColors.emeraldGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double gasLevel =
        (gasDevice.payload['gas_level'] as num?)?.toDouble() ?? 0.0;
    final String status = gasDevice.operationalState;
    final Color statusColor = _getStatusColor(status);

    return CustomContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).gasSensor,
                  style: Styles.style14Medium.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "${S.of(context).gasLevel} ",
                        style: Styles.style12Regular,
                      ),
                      TextSpan(
                        text: "$gasLevel",
                        style:
                            Styles.style12SemiBold.copyWith(color: statusColor),
                      ),
                      TextSpan(
                        text: " ${S.of(context).unitPpmText}",
                        style:
                            Styles.style12Regular.copyWith(color: statusColor),
                      ),
                    ],
                  ),
                )
              ],
            ),
            GasSensorGauge(
              gasLevel: gasLevel,
              status: status,
            ),
          ],
        ),
      ),
    );
  }
}
