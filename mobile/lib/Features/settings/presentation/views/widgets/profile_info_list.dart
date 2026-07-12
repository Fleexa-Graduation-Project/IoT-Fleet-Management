import 'package:fleexa/Features/settings/data/models/profile_field_section_model.dart';
import 'package:fleexa/Features/settings/presentation/views/widgets/profile_field_section.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';

class ProfileInfoList extends StatelessWidget {
  final List<ProfileFieldSectionModel> profileFields;

  const ProfileInfoList({
    super.key,
    required this.profileFields,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(profileFields.length, (index) {
        return Column(
          children: [
            ProfileFieldSection(
              profileFieldSectionModel: profileFields[index],
            ),
            if (index != profileFields.length - 1)
              const Divider(
                color: AppColors.dimGray,
                height: 32,
              ),
          ],
        );
      }),
    );
  }
}
