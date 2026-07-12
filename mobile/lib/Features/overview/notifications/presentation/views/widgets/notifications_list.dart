import 'dart:developer';

import 'package:fleexa/Features/overview/notifications/presentation/manager/notifications_cubit.dart';
import 'package:fleexa/core/widgets/error_page.dart';
import 'package:fleexa/generated/l10n.dart';

import 'package:fleexa/Features/overview/notifications/presentation/views/widgets/notification_card.dart';
import 'package:fleexa/core/router/app_router.dart';
import 'package:fleexa/core/widgets/skelton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/utils/constants/app_colors.dart';
import '../../../../../../core/utils/constants/styles.dart';
import '../../manager/notifications_state.dart';

class NotificationsList extends StatelessWidget {
  const NotificationsList({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        if (state is NotificationsLoading || state is NotificationsInitial) {
          log('NotificationsList: ${state.runtimeType}');
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            itemCount: 10,
            itemBuilder: (context, index) => const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Skelton(height: 85, width: double.infinity),
            ),
          );
        } else if (state is NotificationsError) {
          return ErrorPage(
            onRetry: () {
              context.read<NotificationsCubit>().loadNotifications();
            },
            type: state.errorType,
          );
        } else if (state is NotificationsLoaded) {
          final notifications = state.groupedAlerts;

          if (notifications.values.every((list) => list.isEmpty)) {
            return Center(
              child: Text(
                S.of(context).youAreAllCaughtUp,
                style: Styles.style16Medium.copyWith(color: AppColors.coolGray),
              ),
            );
          }

          return ListView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            children: [
              ...notifications.entries.map((entry) {
                final groupName = entry.key;
                final alerts = entry.value;

                if (alerts.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, top: 16),
                      child: Text(
                        groupName,
                        style: Styles.style14Medium
                            .copyWith(color: AppColors.coolGray),
                      ),
                    ),
                    ...alerts.map(
                      (alert) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: NotificationCard(
                          alert: alert,
                          onTap: () {
                            context
                                .read<NotificationsCubit>()
                                .markAsRead(alert);
                            if (alert.deviceId.contains('door')) {
                              GoRouter.of(context)
                                  .pushNamed(AppRouter.doorLockControl);
                            } else if (alert.deviceId.contains('gas')) {
                              GoRouter.of(context)
                                  .pushNamed(AppRouter.gasSensor);
                            }
                          },
                          onDismiss: () {
                            context
                                .read<NotificationsCubit>()
                                .markAsRead(alert);
                          },
                        ),
                      ),
                    ),
                  ],
                );
              }),
              if (state.isFetchingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.wineRed,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }
}
