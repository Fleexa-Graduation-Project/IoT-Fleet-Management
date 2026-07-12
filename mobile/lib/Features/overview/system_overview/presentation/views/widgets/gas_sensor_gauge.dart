import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class GasSensorGauge extends StatelessWidget {
  final double gasLevel;
  final String status; 

  const GasSensorGauge({
    super.key,
    required this.gasLevel,
    required this.status,
  });

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

  String _getLocalizedStatusText(BuildContext context) {
    switch (status.toUpperCase()) {
      case 'SAFE':
      case 'NORMAL':
        return S.of(context).statusSafe;
      case 'WARNING':
        return S.of(context).statusWarning;
      case 'CRITICAL':
      case 'DANGER':
        return S.of(context).statusCritical;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _getStatusColor();
    final double maxGaugeValue = 1000.0;
    final double pointerValue =
        gasLevel > maxGaugeValue ? maxGaugeValue : gasLevel;

    return SizedBox(
      height: 100,
      width: 100,
      child: SfRadialGauge(
        enableLoadingAnimation: true,
        animationDuration: 2000,
        axes: <RadialAxis>[
          RadialAxis(
            minimum: 0,
            maximum: maxGaugeValue,
            showLabels: false,
            showTicks: false,
            startAngle: 135,
            endAngle: 45,
            radiusFactor: 1.0,
            axisLineStyle: AxisLineStyle(
              thickness: 8,
              color: Colors.white.withOpacity(0.1),
              cornerStyle: CornerStyle.bothCurve,
            ),
            pointers: <GaugePointer>[
              RangePointer(
                value: pointerValue,
                width: 8,
                cornerStyle: CornerStyle.bothCurve,
                enableAnimation: true,
                animationDuration: 1300,
                animationType: AnimationType.ease,
                gradient: SweepGradient(
                  colors: <Color>[
                    currentColor.withOpacity(0.3),
                    currentColor,
                  ],
                  stops: const <double>[0.1, 1],
                ),
              ),
              MarkerPointer(
                value: pointerValue,
                markerType: MarkerType.circle,
                color: currentColor,
                markerHeight: 12,
                markerWidth: 12,
                enableAnimation: true,
                animationDuration: 1300,
                animationType: AnimationType.ease,
              )
            ],
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
               
                positionFactor: 0,
                widget: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 500),
                  style: Styles.style12Regular.copyWith(
                    color: currentColor,
                    fontWeight: FontWeight.bold,
                  ),
                  child: Text(_getLocalizedStatusText(context)),
                ),
                angle: 90,
              )
            ],
          ),
        ],
      ),
    );
  }
}
