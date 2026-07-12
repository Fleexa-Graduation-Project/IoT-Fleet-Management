import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/utils/constants/app_colors.dart';
import '../../../../../../core/utils/constants/styles.dart';
import '../../../../../../generated/l10n.dart';
import '../../../../../auth/presentation/manager/auth_cubit.dart';

class HomeAppbarWelcoming extends StatelessWidget {
  const HomeAppbarWelcoming({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: S.of(context).homeHello,
            style: Styles.style20SemiBold,
            children: [
              TextSpan(
                text: " ${context.watch<AuthCubit>().username}!",
                style: Styles.style20SemiBold.copyWith(
                  color: AppColors.burgundy,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          S.of(context).homeWelcome,
          style: Styles.style16Regular,
        ),
      ],
    );
  }
}
