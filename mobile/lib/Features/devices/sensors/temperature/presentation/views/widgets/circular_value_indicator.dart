import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';

class CircularValueIndicator extends StatelessWidget {
  const CircularValueIndicator({
    super.key,
    required this.value,
  });
  final double value;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.transparent,
                AppColors.burgundy.withOpacity(0.12),
                AppColors.darkMaroon.withOpacity(0.09),
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
          ),
        ),
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.dimGray.withOpacity(0.6),
              width: 10,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value.toStringAsFixed(0),
                style: Styles.style28SemiBold,
              ),
              const SizedBox(height: 4),
              Text(
                S.of(context).unitCelsiusText,
                style: Styles.style14Regular.copyWith(
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
