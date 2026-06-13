import 'package:everroute/models/notification_model.dart';
import 'package:go_router/go_router.dart';

void navigateForNotification(GoRouter router, NotificationModel notification) {
  final entityType = notification.entityType;
  final entityId = notification.entityId?.trim() ?? '';
  switch (notification.type) {
    case 'assignment_created':
    case 'assignment_assigned':
    case 'assignment_status_changed':
    case 'assignment_completed':
    case 'assignment_cancelled':
    case 'family_link_expiring':
      if (entityId.isNotEmpty) {
        router.push('/assignments/$entityId');
      } else {
        router.go('/assignments');
      }
      return;
    case 'staff_invite_accepted':
    case 'staff_joined':
      if (entityType == 'staff' && entityId.isNotEmpty) {
        router.push('/staff/$entityId');
      } else {
        router.go('/staff');
      }
      return;
    case 'trial_ending_soon':
    case 'trial_ended':
    case 'payment_failed':
    case 'subscription_canceled':
      router.go('/settings?billing=payment');
      return;
    case 'org_settings_updated':
      router.go('/settings');
      return;
    case 'staff_invite_failed':
      router.go('/staff');
      return;
    default:
      if (entityType == 'assignment' && entityId.isNotEmpty) {
        router.push('/assignments/$entityId');
      }
  }
}
