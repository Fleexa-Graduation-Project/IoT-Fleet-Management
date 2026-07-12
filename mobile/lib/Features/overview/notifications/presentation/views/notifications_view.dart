import 'package:fleexa/core/widgets/custom_appbar.dart';
import 'package:fleexa/core/widgets/custom_refresh_indicator.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../manager/notifications_cubit.dart';
import 'widgets/notifications_list.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationsCubit>().loadMoreNotifications();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(
        title: S.of(context).homeNotifications,
        readAllButton: true,
        onReadAll: () {
          context.read<NotificationsCubit>().markAllRead();
        },
      ),
      body: SafeArea(
        child: CustomRefreshIndicator(
          onRefresh: () async {
            await context.read<NotificationsCubit>().loadNotifications();
          },
          child: Center(
              child: NotificationsList(scrollController: _scrollController)),
        ),
      ),
    );
  }
}
