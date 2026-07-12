import 'package:fleexa/Features/settings/data/models/profile_field_section_model.dart';
import 'package:fleexa/Features/settings/presentation/views/widgets/profile_info_list.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../auth/presentation/manager/auth_cubit.dart';

class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        color: AppColors.settingCard,
      ),
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
        child: ProfileInfoList(
          profileFields: [
            ProfileFieldSectionModel(
              title: S.of(context).fieldUsername,
              subtitle: context.watch<AuthCubit>().username,
              icon: Icons.person_outline,
            ),
            ProfileFieldSectionModel(
              title: S.of(context).fieldEmail,
              subtitle: context.watch<AuthCubit>().email,
              icon: Icons.email_outlined,
            ),
          ],
        ),
      ),
    );
  }
}
