import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:fleexa/core/utils/functions/format_date_time.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';

class SystemOverviewHeader extends StatelessWidget {
  const SystemOverviewHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          S.of(context).systemOverview,
          style: Styles.style20SemiBold,
        ),
        const SizedBox(height: 10),
        Text(
          formatDate(DateTime.now()), 
          style: Styles.style12Medium.copyWith(color: AppColors.coolGray),
        )
      ],
    );
  }
}
