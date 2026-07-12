import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/utils/constants/app_colors.dart';
import '../../../../../core/utils/constants/styles.dart';

class SettingsCard extends StatelessWidget {
  const SettingsCard({
    super.key,
    required this.title,
    required this.icon,
    this.pageRouteName,
    this.forwardArrow = false,
    this.dropDown,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final Widget? dropDown;
  final bool forwardArrow;
  final String? pageRouteName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (pageRouteName != null) {
          GoRouter.of(context).pushNamed(pageRouteName!);
        }
        onTap?.call();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.charcoalBlack,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.darkGray,
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: AppColors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: Styles.style16Medium,
            ),
            const Spacer(),
            if (forwardArrow)
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.coolGray,
                size: 16,
              ),
            if (dropDown != null) dropDown!,
          ],
        ),
      ),
    );
  }
}
