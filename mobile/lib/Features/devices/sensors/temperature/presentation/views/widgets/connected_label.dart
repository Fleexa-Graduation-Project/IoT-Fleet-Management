import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';

class ConnectedLabel extends StatelessWidget {
  const ConnectedLabel({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.emeraldGreen,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(
          width: 4,
        ),
        Text(
          S.of(context).statusConnected,
          style: Styles.style12Medium.copyWith(color: AppColors.white50),
        ),
      ],
    );
  }
}
