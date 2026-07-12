import 'dart:async';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fleexa/Features/overview/notifications/data/repos/notifications_repository.dart';

import '../../../../../core/errors/error_handler.dart';
import '../../../../../core/services/push_notification_service.dart';
import '../../../../../core/setup/service_locator.dart';
import '../../../../devices/shared/data/models/alert_model.dart';
import '../../../../devices/shared/data/models/ui_alert_model.dart';
import 'notifications_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationsRepository repository;

  StreamSubscription? _pushSubscription;
  String? _nextCursor;
  bool _hasReachedMax = false;
  bool _isFetchingMore = false;

  NotificationsCubit(this.repository) : super(NotificationsInitial()) {
    _pushSubscription = getIt<PushNotificationService>()
        .onNotificationReceived
        .listen((RemoteMessage message) {
      log('NotificationCubit heared a new push! Reloading list silently...');
      loadNotifications(showLoading: false, isRefresh: true);
    });
  }

  List<UIAlertModel> _currentAlerts = [];

  Future<void> loadNotifications(
      {bool showLoading = true, bool isRefresh = false}) async {
    if (showLoading) {
      emit(NotificationsLoading());
    }

    try {
      log("Fetching initial alerts...");
      final result = await repository.getAllSystemAlerts(limit: 20);
      log("Fetched ${result.alerts.length} alerts. Next Cursor: ${result.nextCursor}");

      _nextCursor = result.nextCursor;
      _hasReachedMax = _nextCursor == null;

      _processAlerts(result.alerts, isAppend: false);
    } catch (e) {
      log('CRASH REASON IN LOAD: $e');
      final type = ErrorHandler.getErrorType(e);
      emit(NotificationsError(
          errorType: type, message: 'Failed to load notifications: $e'));
    }
  }

  Future<void> loadMoreNotifications() async {
    if (_hasReachedMax || _isFetchingMore) {
      log("Skipping loadMore. hasReachedMax: $_hasReachedMax, isFetchingMore: $_isFetchingMore");
      return;
    }

    _isFetchingMore = true;
    _emitGrouped();

    try {
      log("Fetching more alerts with cursor: $_nextCursor...");
      final result = await repository.getAllSystemAlerts(
        limit: 20,
        beforeCursor: _nextCursor,
      );
      log("Fetched ${result.alerts.length} MORE alerts. New Cursor: ${result.nextCursor}");

      _nextCursor = result.nextCursor;
      _hasReachedMax = _nextCursor == null;

      _processAlerts(result.alerts, isAppend: true);
    } catch (e) {
      log("CRASH REASON IN LOAD MORE: $e");
      _isFetchingMore = false;
      _emitGrouped();
    }
  }

  void _processAlerts(List<AlertModel> rawAlerts, {required bool isAppend}) {
    final newUiAlerts = rawAlerts
        .map((apiModel) => UIAlertModel.fromAlertModel(apiModel))
        .toList();

    if (isAppend) {
      _currentAlerts.addAll(newUiAlerts);
    } else {
      _currentAlerts = newUiAlerts;
    }

    _isFetchingMore = false;
    _emitGrouped();
  }

  void markAllRead() async {
    log("Marking ALL alerts as read...");

    final unreadAlerts =
        _currentAlerts.where((alert) => !alert.isRead).toList();
    log("Found ${unreadAlerts.length} unread alerts to process.");

    if (unreadAlerts.isEmpty) return;

    _currentAlerts =
        _currentAlerts.map((alert) => alert.copyWith(isRead: true)).toList();
    _emitGrouped();

    for (var alert in unreadAlerts) {
      try {
        await repository.markAlertAsRead(alert.alertId);
        log("SUCCESS: Alert ${alert.alertId} marked read in backend.");
      } catch (e) {
        log("FAILED to mark alert ${alert.alertId} as read: $e");
        // هنا جنى طلبت إننا نرجع الإشعار Unread لو فشل
        _revertAlertToUnread(alert.alertId);
      }
    }
  }

  void markAsRead(UIAlertModel targetAlert) async {
    if (targetAlert.isRead) {
      log("Alert ${targetAlert.alertId} is already read, skipping...");
      return;
    }

    log("Marking ONE alert as read: ${targetAlert.alertId}");

    // 1. Update UI state (Optimistic)
    _currentAlerts = _currentAlerts.map((alert) {
      if (alert.alertId == targetAlert.alertId) {
        return alert.copyWith(isRead: true);
      }
      return alert;
    }).toList();
    _emitGrouped();

    // 2. Send to backend
    try {
      await repository.markAlertAsRead(targetAlert.alertId);
      log("SUCCESS: Alert ${targetAlert.alertId} marked as read in backend.");
    } catch (e) {
      log("FAILED: Reverting UI for ${targetAlert.alertId}. Error: $e");
      _revertAlertToUnread(targetAlert.alertId);
    }
  }

  void _revertAlertToUnread(String alertId) {
    _currentAlerts = _currentAlerts.map((alert) {
      if (alert.alertId == alertId) {
        return alert.copyWith(isRead: false);
      }
      return alert;
    }).toList();
    _emitGrouped();
  }

  void _emitGrouped() {
    final Map<String, List<UIAlertModel>> grouped = {
      'Today': [],
      'Yesterday': [],
      'Earlier': [],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var alert in _currentAlerts) {
      final alertDate = DateTime(
          alert.dateTime.year, alert.dateTime.month, alert.dateTime.day);

      if (alertDate == today) {
        grouped['Today']!.add(alert);
      } else if (alertDate == yesterday) {
        grouped['Yesterday']!.add(alert);
      } else {
        grouped['Earlier']!.add(alert);
      }
    }

    emit(NotificationsLoaded(
      grouped,
      isFetchingMore: _isFetchingMore,
      hasReachedMax: _hasReachedMax,
    ));
  }

  void clearData() {
    _currentAlerts = [];
    emit(NotificationsInitial());
  }

  @override
  Future<void> close() {
    _pushSubscription?.cancel();
    return super.close();
  }
}
