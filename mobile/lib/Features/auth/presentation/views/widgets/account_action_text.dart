import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:flutter/material.dart';

class AccountActionText extends StatelessWidget {
  final String normalText;
  final String actionText;
  final VoidCallback onTap;

  const AccountActionText({
    super.key,
    required this.normalText,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(normalText, style: Styles.style14Medium),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionText,
            style: Styles.style14Medium.copyWith(
              color: AppColors.burgundy,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.burgundy,
              decorationThickness: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
