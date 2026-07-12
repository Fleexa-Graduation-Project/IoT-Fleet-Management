import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/assets.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class LightSensorGauge extends StatelessWidget {
  final double luxValue;

  const LightSensorGauge({super.key, required this.luxValue});

  @override
  Widget build(BuildContext context) {
    double gaugeValue = luxValue.clamp(0, 1000);

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Colors.transparent,
                AppColors.burgundy.withOpacity(0.12),
                AppColors.darkMaroon.withOpacity(0.09),
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
            shape: BoxShape.circle,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 250,
              child: SfRadialGauge(
                axes: <RadialAxis>[
                  RadialAxis(
                    minimum: 0,
                    maximum: 1000,
                    startAngle: 180,
                    endAngle: 0,
                    showLabels: false,
                    showTicks: true,
                    axisLineStyle: const AxisLineStyle(
                      thickness: 3,
                      color: AppColors.dimGray,
                    ),
                    majorTickStyle: const MajorTickStyle(
                      length: 14,
                      thickness: 3,
                      color: AppColors.dimGray,
                    ),
                    minorTicksPerInterval: 0,
                    pointers: <GaugePointer>[
                      /// THE ARROW INDICATOR
                      NeedlePointer(
                        value: gaugeValue,
                        lengthUnit: GaugeSizeUnit.factor,
                        needleLength: 0.77,
                        needleStartWidth: 1,
                        needleEndWidth: 40,
                        knobStyle: const KnobStyle(knobRadius: 0),
                        needleColor: AppColors.dimGray,
                        enableAnimation: true,
                        animationType: AnimationType.easeOutBack,
                      ),
                    ],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                        widget: Text(S.of(context).statusDark,
                            style: Styles.style12Medium
                                .copyWith(color: AppColors.white50)),
                        angle: 180,
                        positionFactor: 1.2,
                      ),
                      GaugeAnnotation(
                        widget: Text(S.of(context).statusNormal,
                            style: Styles.style12Medium
                                .copyWith(color: AppColors.white50)),
                        angle: 270,
                        positionFactor: 1.2,
                      ),
                      GaugeAnnotation(
                        widget: Text(S.of(context).statusBright,
                            style: Styles.style12Medium
                                .copyWith(color: AppColors.white50)),
                        angle: 0,
                        positionFactor: 1.2,
                      ),
                      // Center Hub
                      GaugeAnnotation(
                        positionFactor: 0,
                        widget: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.richBlack,
                            border:
                                Border.all(color: AppColors.dimGray, width: 10),
                            // Optional: Inner shadow for depth
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(AppAssets.iconsLamp),
                              const SizedBox(height: 10),
                              Text(
                                  '${luxValue.toInt()} ${S.of(context).unitLuxText}',
                                  style: Styles.style18Medium),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
