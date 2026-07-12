import 'package:fleexa/core/utils/constants/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
            radius: 55.r,
            backgroundImage: const AssetImage(AppAssets.imagesMan)),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.camera_alt,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}
