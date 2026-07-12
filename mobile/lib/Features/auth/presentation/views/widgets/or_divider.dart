import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: Container(height: 2, color: AppColors.dimGray)),
        const SizedBox(width: 8),
        Text(S.of(context).authOr, style: Styles.style14Medium),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 2, color: AppColors.dimGray)),
      ],
    );
  }
}
