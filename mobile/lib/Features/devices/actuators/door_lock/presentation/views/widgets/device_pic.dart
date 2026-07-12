import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class DevicePic extends StatelessWidget {
  const DevicePic({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 120,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: AppColors.burgundy.withOpacity(0.35),
                blurRadius: 80,
                spreadRadius: 20,
              ),
            ],
          ),
        ),
        SvgPicture.asset(
          'assets/images/door_lock_device.svg',
          width: 180,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}
