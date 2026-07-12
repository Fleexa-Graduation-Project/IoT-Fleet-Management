import 'package:fleexa/core/router/app_router.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/generated/l10n.dart';

import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GetStartedButton extends StatelessWidget {
  const GetStartedButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        GoRouter.of(context).goNamed(AppRouter.signIn);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 14),
        decoration: ShapeDecoration(
          color: AppColors.darkMaroon,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          S.of(context).getStarted,
          textAlign: TextAlign.center,
          style: Styles.style20Medium,
        ),
      ),
    );
  }
}
