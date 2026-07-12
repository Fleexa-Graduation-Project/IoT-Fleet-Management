import 'package:fleexa/Features/overview/home/presentation/views/widgets/home_appbar_welcoming.dart';

import 'package:fleexa/Features/overview/home/presentation/views/widgets/top_appbar_action_row.dart';
import 'package:flutter/material.dart';

import '../../../../../../core/utils/constants/app_colors.dart';

class HomeAppbar extends StatelessWidget {
  const HomeAppbar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TopAppbarActionRow(),
        SizedBox(height: 12),
        HomeAppbarWelcoming(),
        Divider(height: 24, color: AppColors.darkGray),
      ],
    );
  }
}
