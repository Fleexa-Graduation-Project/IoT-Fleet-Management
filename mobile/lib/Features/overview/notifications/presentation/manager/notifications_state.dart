import '../../../../../core/utils/constants/app_strings.dart';
import '../../../../devices/shared/data/models/ui_alert_model.dart';

abstract class NotificationsState {}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsError extends NotificationsState {
  final String message;
  final ErrorType errorType;
  NotificationsError({required this.message, required this.errorType});
}

class NotificationsLoaded extends NotificationsState {
  final Map<String, List<UIAlertModel>> groupedAlerts;
  final bool isFetchingMore;
  final bool hasReachedMax;
  NotificationsLoaded(
    this.groupedAlerts, {
    this.hasReachedMax = false,
    this.isFetchingMore = false,
  });
}
