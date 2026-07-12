import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/widgets/custom_container.dart';
import '../../../../../../../../core/utils/constants/app_colors.dart';
import '../../../../../../../../core/utils/constants/styles.dart';
import '../../../../../../../../generated/l10n.dart';

class RelatedDeviceCard extends StatelessWidget {
  const RelatedDeviceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        GoRouter.of(context).pushNamed(AppRouter.temperatureSensor);
      },
      child: CustomContainer(
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/icons/temp_sensor.svg',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 16),
            Text(
              S.of(context).temperatureSensor,
              style: Styles.style14Medium.copyWith(color: AppColors.white),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.coolGray,
            ),
          ],
        ),
      ),
    );
  }
}
