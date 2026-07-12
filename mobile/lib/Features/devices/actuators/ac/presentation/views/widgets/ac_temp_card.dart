import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../../../core/widgets/custom_container.dart';
import '../../../../../../../../core/utils/constants/app_colors.dart';
import '../../../../../../../../core/utils/constants/styles.dart';
import '../../../../../../../../generated/l10n.dart';

class AcTempCard extends StatelessWidget {
  const AcTempCard(
      {super.key, required this.isOutside, required this.temperature});

  final bool isOutside;
  final num temperature;

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      horizontalPadding: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            isOutside
                ? 'assets/icons/temp_outside.svg'
                : 'assets/icons/temp_sensor.svg',
            width: 36,
          ),
          const Spacer(),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${temperature.toInt()}°', style: Styles.style24Medium),
              Text(
                isOutside
                    ? S.of(context).tempOutside
                    : S.of(context).tempInside,
                style: Styles.style14Regular.copyWith(
                  color: AppColors.coolGray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
