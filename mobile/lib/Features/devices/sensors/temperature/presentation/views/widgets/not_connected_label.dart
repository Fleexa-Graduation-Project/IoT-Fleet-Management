import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:fleexa/generated/l10n.dart';

class NotConnectedLabel extends StatelessWidget {
  const NotConnectedLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.burgundy, // or any offline color you use
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          S.of(context).statusDisconnected,
          style: Styles.style12Medium.copyWith(
            color: AppColors.white50,
          ),
        ),
      ],
    );
  }
}