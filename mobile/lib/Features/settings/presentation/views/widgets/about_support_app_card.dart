import 'package:fleexa/core/widgets/custom_container.dart';
import 'package:fleexa/generated/l10n.dart';

import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AboutSupportAppCard extends StatelessWidget {
  const AboutSupportAppCard({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: AppColors.darkGray,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: const Icon(
              Icons.home_work_outlined,
              color: AppColors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.of(context).fleexa, style: Styles.style18SemiBold),
                const SizedBox(height: 2),
                Text(S.of(context).smartHomeVersion100,
                  style:
                      Styles.style14Regular.copyWith(color: AppColors.coolGray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
