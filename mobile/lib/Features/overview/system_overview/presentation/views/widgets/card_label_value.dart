import 'package:flutter/material.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';

class CardLabelValue extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const CardLabelValue({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: "$label: ",
            style: Styles.style12Regular.copyWith(color: AppColors.mediumGray),
          ),
          TextSpan(
            text: value,
            style: Styles.style12Medium.copyWith(
              color: valueColor ?? AppColors.burgundy,
            ),
          ),
        ],
      ),
    );
  }
}