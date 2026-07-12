import 'package:fleexa/Features/settings/data/models/profile_field_section_model.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:flutter/material.dart';

class ProfileFieldSection extends StatelessWidget {
  const ProfileFieldSection(
      {super.key, required this.profileFieldSectionModel});
  final ProfileFieldSectionModel profileFieldSectionModel;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profileFieldSectionModel.title,
          style: Styles.style14SemiBold.copyWith(color: AppColors.white),
        ),
        const SizedBox(
          height: 16,
        ),
        Row(
          children: [
            Icon(
              profileFieldSectionModel.icon,
              color: AppColors.white,
            ),
            const SizedBox(
              width: 14,
            ),
            Text(
              profileFieldSectionModel.subtitle,
              style: Styles.style14Regular.copyWith(color: AppColors.white),
            ),
          ],
        ),
      ],
    );
  }
}
