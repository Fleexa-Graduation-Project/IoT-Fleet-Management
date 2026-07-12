import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:flutter/material.dart';

class CustomContainerRow extends StatelessWidget {
  const CustomContainerRow({
    super.key,
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Styles.style14Medium.copyWith(color: AppColors.white),
        ),
        const Spacer(),
        Text(
          value,
          style: Styles.style12Medium.copyWith(color: AppColors.coolGray),
        ),
      ],
    );
  }
}
