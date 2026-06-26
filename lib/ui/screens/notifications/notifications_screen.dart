import 'package:everroute/core/navigation/notification_navigation.dart';
import 'package:everroute/core/theme/app_theme.dart';
import 'package:everroute/features/notifications/notifications_cubit.dart';
import 'package:everroute/features/notifications/notifications_state.dart';
import 'package:everroute/features/session/staff_auth.dart';
import 'package:everroute/models/notification_model.dart';
import 'package:everroute/ui/widgets/everroute_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final token = staffBearerToken();
    if (token == null) return;
    await context.read<NotificationsCubit>().load(bearerToken: token);
  }

  Future<void> _refresh() async {
    final token = staffBearerToken();
    if (token == null) return;
    await context.read<NotificationsCubit>().refresh(bearerToken: token);
  }

  Future<void> _delete(NotificationModel notification) async {
    final token = staffBearerToken();
    if (token == null) return;
    try {
      await context.read<NotificationsCubit>().deleteNotification(
        bearerToken: token,
        notificationId: notification.id,
      );
    } catch (e) {
      if (!mounted) return;
      EverrouteSnackBar.error(context, e.toString());
    }
  }

  Future<void> _onTap(NotificationModel notification) async {
    final token = staffBearerToken();
    if (token == null) return;
    if (!notification.isRead) {
      await context.read<NotificationsCubit>().markRead(
        bearerToken: token,
        notificationId: notification.id,
      );
    }
    if (!mounted) return;
    _navigateForNotification(notification);
  }

  void _navigateForNotification(NotificationModel notification) {
    navigateForNotification(GoRouter.of(context), notification);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textPrimary,
          onPressed: () => context.pop(),
        ),
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              if (state.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () async {
                  final token = staffBearerToken();
                  if (token == null) return;
                  await context.read<NotificationsCubit>().markAllRead(
                    bearerToken: token,
                  );
                },
                child: const Text('Mark all read'),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          if (state.busy && state.items.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (state.error != null && state.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            );
          }
          if (state.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No notifications yet.',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: state.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = state.items[index];
                return _NotificationTile(
                  notification: item,
                  onTap: () => _onTap(item),
                  onDelete: () => _delete(item),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final created = notification.createdAt.toLocal();
    final hour = created.hour % 12 == 0 ? 12 : created.hour % 12;
    final minute = created.minute.toString().padLeft(2, '0');
    final amPm = created.hour >= 12 ? 'PM' : 'AM';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final timeLabel =
        '${months[created.month - 1]} ${created.day}, $hour:$minute $amPm';
    return Material(
      color: notification.isRead ? AppColors.surface : const Color(0xFFF3FAF7),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _iconForType(notification.type),
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timeLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, right: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColors.textSecondary,
                tooltip: 'Remove',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'assignment_created':
      case 'assignment_assigned':
      case 'assignment_status_changed':
      case 'assignment_completed':
      case 'assignment_cancelled':
      case 'assignment_deleted':
      case 'family_link_expiring':
        return Icons.assignment_outlined;
      case 'trial_ending_soon':
      case 'trial_ended':
      case 'payment_failed':
      case 'subscription_canceled':
        return Icons.payment_outlined;
      case 'staff_invite_accepted':
      case 'staff_joined':
      case 'staff_invite_failed':
        return Icons.people_outline_rounded;
      case 'org_settings_updated':
        return Icons.settings_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }
}
