import 'package:fleexa/core/router/app_router.dart';
import 'package:fleexa/core/widgets/custom_container.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/assets.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class RelatedDeviceCard extends StatelessWidget {
  const RelatedDeviceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).labelRelatedDevices,
          style: Styles.style18Medium,
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () {
            GoRouter.of(context).pushNamed(AppRouter.acControl);
          },
          child: CustomContainer(
              child: Row(
            children: [
              SvgPicture.asset(
                AppAssets.iconsAc,
              ),
              const SizedBox(
                width: 16,
              ),
              Text(
                S.of(context).airConditioner,
                style: Styles.style14Medium.copyWith(color: AppColors.white),
              ),
              const SizedBox(height: 4),
              const Spacer(),
              const Icon(
                FontAwesomeIcons.angleRight,
                color: AppColors.mediumGray,
              )
            ],
          )),
        )
      ],
    );
  }
}
