import 'package:fleexa/Features/overview/notifications/presentation/views/widgets/notification_bell_badge.dart';

import 'package:fleexa/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

// import '../../../../../../core/utils/constants/app_colors.dart';

class TopAppbarActionRow extends StatelessWidget {
  const TopAppbarActionRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/images/letter_logo.svg',
          width: 28,
        ),
        const Spacer(),
        NotificationBellBadge(onTap: () {
          GoRouter.of(context).pushNamed(AppRouter.notifications);
        }),
        const SizedBox(width: 4),
        // IconButton(
        //   onPressed: () {},
        //   icon: const Icon(
        //     Icons.power_settings_new_rounded,
        //     fontWeight: FontWeight.w600,
        //     size: 24,
        //     color: AppColors.white,
        //   ),
        // ),
      ],
    );
  }
}
