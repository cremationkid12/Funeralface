import 'package:everroute/models/notification_model.dart';

class NotificationsState {
  const NotificationsState({
    this.busy = false,
    this.refreshing = false,
    this.items = const [],
    this.unreadCount = 0,
    this.error,
  });

  final bool busy;
  final bool refreshing;
  final List<NotificationModel> items;
  final int unreadCount;
  final String? error;

  NotificationsState copyWith({
    bool? busy,
    bool? refreshing,
    List<NotificationModel>? items,
    int? unreadCount,
    String? error,
    bool clearError = false,
  }) {
    return NotificationsState(
      busy: busy ?? this.busy,
      refreshing: refreshing ?? this.refreshing,
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
