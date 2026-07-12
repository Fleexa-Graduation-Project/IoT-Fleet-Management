import 'package:fleexa/Features/overview/notifications/presentation/manager/notifications_cubit.dart';
import 'package:fleexa/Features/overview/notifications/presentation/manager/notifications_state.dart';
import 'package:fleexa/core/utils/constants/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../../../core/utils/constants/app_colors.dart';

class NotificationBellBadge extends StatelessWidget {
  const NotificationBellBadge({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            AppAssets.iconsNotification,
            width: 24,
            height: 24,
          ),
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              bool hasUnread = false;

              if (state is NotificationsLoaded) {
                for (var group in state.groupedAlerts.values) {
                  if (group.any((alert) => !alert.isRead)) {
                    hasUnread = true;
                    break;
                  }
                }
              }

              if (!hasUnread) return const SizedBox.shrink();

              return Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.crimsonRed,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.charcoalBlack, width: 2),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
