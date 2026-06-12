import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:everroute/features/notifications/notifications_state.dart';
import 'package:everroute/models/notification_model.dart';
import 'package:everroute/services/notifications_services.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({required NotificationsServices notificationsServices})
    : _notificationsServices = notificationsServices,
      super(const NotificationsState());

  final NotificationsServices _notificationsServices;

  Future<void> load({required String bearerToken}) async {
    emit(state.copyWith(busy: true, clearError: true));
    try {
      final result = await _notificationsServices.list(bearerToken: bearerToken);
      emit(
        state.copyWith(
          busy: false,
          items: result.items,
          unreadCount: result.unreadCount,
          error: null,
        ),
      );
    } catch (error) {
      emit(state.copyWith(busy: false, error: error.toString()));
    }
  }

  Future<void> refresh({required String bearerToken}) async {
    emit(state.copyWith(refreshing: true, clearError: true));
    try {
      final result = await _notificationsServices.list(bearerToken: bearerToken);
      emit(
        state.copyWith(
          refreshing: false,
          items: result.items,
          unreadCount: result.unreadCount,
          error: null,
        ),
      );
    } catch (error) {
      emit(state.copyWith(refreshing: false, error: error.toString()));
    }
  }

  Future<void> refreshUnreadCount({required String bearerToken}) async {
    try {
      final unreadCount = await _notificationsServices.getUnreadCount(
        bearerToken: bearerToken,
      );
      emit(state.copyWith(unreadCount: unreadCount, clearError: true));
    } catch (_) {
      // Non-fatal for badge refresh.
    }
  }

  Future<void> markRead({
    required String bearerToken,
    required String notificationId,
  }) async {
    try {
      final unreadCount = await _notificationsServices.markRead(
        bearerToken: bearerToken,
        notificationId: notificationId,
      );
      final items = state.items
          .map(
            (item) => item.id == notificationId
                ? NotificationModel(
                    id: item.id,
                    type: item.type,
                    title: item.title,
                    body: item.body,
                    entityType: item.entityType,
                    entityId: item.entityId,
                    readAt: DateTime.now(),
                    createdAt: item.createdAt,
                  )
                : item,
          )
          .toList();
      emit(state.copyWith(items: items, unreadCount: unreadCount));
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  Future<void> markAllRead({required String bearerToken}) async {
    try {
      await _notificationsServices.markAllRead(bearerToken: bearerToken);
      final items = state.items
          .map(
            (item) => NotificationModel(
              id: item.id,
              type: item.type,
              title: item.title,
              body: item.body,
              entityType: item.entityType,
              entityId: item.entityId,
              readAt: item.readAt ?? DateTime.now(),
              createdAt: item.createdAt,
            ),
          )
          .toList();
      emit(state.copyWith(items: items, unreadCount: 0));
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  void clear() {
    emit(const NotificationsState());
  }
}
