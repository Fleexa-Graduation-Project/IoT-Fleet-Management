import 'package:fleexa/Features/devices/sensors/gas/presentation/views/widgets/gas_radial_gauge.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';

class GasSensorGaugeWidget extends StatelessWidget {
  final double ppmValue;
  final String status;

  const GasSensorGaugeWidget({
    super.key,
    required this.ppmValue,
    required this.status,
  });

  // Color _getStatusColor() {
  //   if (ppmValue < 300) return AppColors.emeraldGreen;
  //   if (ppmValue < 600) return AppColors.copperOrange;
  //   return AppColors.burgundy;
  // }
  Color _getStatusColor() {
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
    final statusColor = _getStatusColor();

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.transparent,
                  statusColor.withOpacity(0.13),
                  statusColor.withOpacity(0.05),
                ],
                stops: const [0.2, 0.5, 1.0],
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                radius: 0.8,
                colors: [
                  statusColor.withOpacity(0.2),
                  statusColor.withOpacity(0.1),
                  statusColor.withOpacity(0.02),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 0.6, 1.0],
              ),
            ),
          ),
          GasRadialGauge(
              ppmValue: ppmValue, status: status, statusColor: statusColor)
        ],
      ),
    );
  }
}
