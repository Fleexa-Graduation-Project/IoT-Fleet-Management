import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class GasRadialGauge extends StatelessWidget {
  const GasRadialGauge({
    super.key,
    required this.ppmValue,
    required this.status,
    required this.statusColor,
    this.min = 0,
    this.max = 1000,
  });

  final double ppmValue;
  final String status;
  final Color statusColor;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) {
    return SfRadialGauge(
      axes: <RadialAxis>[
        RadialAxis(
          minimum: min,
          maximum: max,
          startAngle: 130,
          endAngle: 50,
          showLabels: true,
          showTicks: true,
          radiusFactor: 0.95,
          labelsPosition: ElementsPosition.outside,
          ticksPosition: ElementsPosition.outside,
          labelOffset: 20,
          tickOffset: 5,
          axisLabelStyle: const GaugeTextStyle(
            color: Colors.white54,
            fontSize: 14,
          ),
          majorTickStyle: const MajorTickStyle(
            length: 12,
            thickness: 2,
            color: Colors.white54,
          ),
          axisLineStyle: AxisLineStyle(
            thickness: 10,
            color: Colors.white.withOpacity(0.1),
            cornerStyle: CornerStyle.bothCurve,
          ),
          annotations: <GaugeAnnotation>[
            GaugeAnnotation(
              positionFactor: 0,
              widget: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: _CenterGaugeContent(
                      ppmValue: ppmValue,
                      status: status,
                    ),
                  );
                },
              ),
            ),
          ],
          pointers: <GaugePointer>[
            RangePointer(
              value: ppmValue,
              width: 12,
              enableAnimation: true,
              animationDuration: 1300,
              cornerStyle: CornerStyle.bothCurve,
              gradient: SweepGradient(
                colors: <Color>[
                  statusColor.withOpacity(0.3),
                  statusColor,
                ],
                stops: const <double>[0.1, 1],
              ),
            ),
            MarkerPointer(
              value: ppmValue,
              enableAnimation: true,
              animationDuration: 1300,
              animationType: AnimationType.ease,
              markerType: MarkerType.circle,
              color: statusColor,
              markerHeight: 15,
              markerWidth: 15,
            ),
          ],
        ),
      ],
    );
  }
}

class _CenterGaugeContent extends StatelessWidget {
  const _CenterGaugeContent({
    required this.ppmValue,
    required this.status,
  });

  final double ppmValue;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      height: 190,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 12,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${ppmValue.toInt()} PPM',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            status,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
