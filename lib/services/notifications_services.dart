import 'package:everroute/models/notification_model.dart';
import '../core/network/api_client.dart';

class NotificationsServices {
  NotificationsServices(this._apiClient);

  final ApiClient _apiClient;

  Future<({List<NotificationModel> items, int unreadCount})> list({
    required String bearerToken,
    int limit = 50,
  }) async {
    final json = await _apiClient.getJson(
      '/v1/notifications?limit=$limit',
      bearerToken: bearerToken,
    );
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    final items = rawItems
        .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
        .toList();
    final unreadCount = (json['unread_count'] as num?)?.toInt() ?? 0;
    return (items: items, unreadCount: unreadCount);
  }

  Future<int> getUnreadCount({required String bearerToken}) async {
    final json = await _apiClient.getJson(
      '/v1/notifications/unread-count',
      bearerToken: bearerToken,
    );
    return (json['unread_count'] as num?)?.toInt() ?? 0;
  }

  Future<int> markRead({
    required String bearerToken,
    required String notificationId,
  }) async {
    final json = await _apiClient.patchJson(
      '/v1/notifications/$notificationId/read',
      body: const <String, dynamic>{},
      bearerToken: bearerToken,
    );
    return (json['unread_count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markAllRead({required String bearerToken}) async {
    await _apiClient.postJson(
      '/v1/notifications/read-all',
      body: const <String, dynamic>{},
      bearerToken: bearerToken,
    );
  }

  Future<int> deleteNotification({
    required String bearerToken,
    required String notificationId,
  }) async {
    final json = await _apiClient.deleteJson(
      '/v1/notifications/$notificationId',
      bearerToken: bearerToken,
    );
    return (json['unread_count'] as num?)?.toInt() ?? 0;
  }
}
