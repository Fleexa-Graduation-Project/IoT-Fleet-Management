import 'package:el_tooltip/el_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../generated/l10n.dart';
import '../utils/constants/app_colors.dart';
import '../utils/constants/styles.dart';

class InfoButton extends StatelessWidget {
  const InfoButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElTooltip(
      content: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: S.of(context).statusGuide,
              style: Styles.style16Medium,
            ),
            TextSpan(
              text: "${S.of(context).infoStatusSafe} (0 -  299 PPM)\n",
              style: Styles.style16Medium,
            ),
            TextSpan(
              text: "${S.of(context).infoStatusWarning} (300 -  599 PPM)\n",
              style: Styles.style16Medium,
            ),
            TextSpan(
              text: "${S.of(context).infoStatusCritical} (600+ PPM)",
              style: Styles.style16Medium,
            ),
          ],
        ),
      ),
      color: AppColors.charcoalBlack,
      position: ElTooltipPosition.leftStart,
      showArrow: true,
      showModal: true,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: SvgPicture.asset(
          'assets/icons/info.svg',
          width: 24,
        ),
      ),
    );
  }
}
