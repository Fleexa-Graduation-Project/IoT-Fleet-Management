import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

class AcPic extends StatelessWidget {
  const AcPic({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 240,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.burgundy.withOpacity(0.35),
                blurRadius: 40,
                spreadRadius: 12,
              ),
            ],
          ),
        ),
        SvgPicture.asset(
          'assets/images/ac_device.svg',
          width: 240,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}
