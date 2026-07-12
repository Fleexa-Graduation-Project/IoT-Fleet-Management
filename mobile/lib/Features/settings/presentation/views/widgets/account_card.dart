import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    required this.title,
    this.forwardArrow = false,
    this.onTap,
  });

  final String title;
  final bool forwardArrow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
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
              Text(title,
                  style: Styles.style16Medium.copyWith(
                    color:
                        title == "Delete Account" ? AppColors.burgundy : null,
                  )),
              const Spacer(),
              if (forwardArrow)
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.coolGray,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
