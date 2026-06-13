import 'package:everroute/app/app_repositories.dart';
import 'package:everroute/core/push/push_notification_coordinator.dart';
import 'package:everroute/features/notifications/notifications_cubit.dart';
import 'package:everroute/core/trial_prompt_preferences.dart';
import 'package:everroute/core/theme/app_theme.dart';
import 'package:everroute/features/session/auth_session.dart';
import 'package:everroute/features/session/staff_auth.dart';
import 'package:everroute/ui/widgets/trial_prompt_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _trialPromptsScheduled = false;

  @override
  void initState() {
    super.initState();
    AuthSession.instance.addListener(_onAuthSessionChanged);
    PushNotificationCoordinator.instance.addRefreshListener(
      _refreshNotificationBadge,
    );
  }

  @override
  void dispose() {
    AuthSession.instance.removeListener(_onAuthSessionChanged);
    PushNotificationCoordinator.instance.removeRefreshListener(
      _refreshNotificationBadge,
    );
    super.dispose();
  }

  void _onAuthSessionChanged() {
    _trialPromptsScheduled = false;
    _scheduleTrialPromptsIfNeeded();
    _refreshNotificationBadge();
    if (staffBearerToken() != null) {
      PushNotificationCoordinator.instance.registerIfAuthenticated();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleTrialPromptsIfNeeded();
    _refreshNotificationBadge();
    if (staffBearerToken() != null) {
      PushNotificationCoordinator.instance.registerIfAuthenticated();
    }
  }

  void _scheduleTrialPromptsIfNeeded() {
    if (_trialPromptsScheduled || staffBearerToken() == null) return;
    _trialPromptsScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTrialPrompts());
  }

  void _refreshNotificationBadge() {
    final token = staffBearerToken();
    if (token == null) {
      context.read<NotificationsCubit>().clear();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationsCubit>().refreshUnreadCount(bearerToken: token);
    });
  }

  Future<void> _maybeShowTrialPrompts() async {
    if (!mounted) return;
    final token = staffBearerToken();
    if (token == null) return;

    try {
      final sub = await context
          .read<AppRepositories>()
          .billing
          .getSubscription(bearerToken: token);
      if (!mounted) return;

      final prefs = TrialPromptPreferences();

      if (sub.isAppTrial && sub.isSubscribed) {
        final pendingWelcome = await prefs.consumePendingWelcome();
        final shownWelcome = await prefs.hasShownWelcome(sub.orgId);
        if (pendingWelcome || !shownWelcome) {
          if (!mounted) return;
          await showTrialWelcomeDialog(context, subscription: sub);
          await prefs.markWelcomeShown(sub.orgId);
          return;
        }

        if (sub.trialExpiringSoon) {
          final warned = await prefs.hasShownExpiryWarningToday(sub.orgId);
          if (!warned) {
            if (!mounted) return;
            await showTrialExpiringSoonDialog(context, subscription: sub);
            await prefs.markExpiryWarningShownToday(sub.orgId);
          }
        }
      }
    } catch (_) {
      // Non-fatal: app remains usable if billing status cannot be loaded.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: _AppNavBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: widget.navigationShell.goBranch,
      ),
    );
  }
}

class _AppNavBar extends StatelessWidget {
  const _AppNavBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _items = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    _NavItem(
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment,
      label: 'Assignments',
    ),
    _NavItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Staff',
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = i == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onDestinationSelected(i),
                  behavior: HitTestBehavior.opaque,
                  child: _NavBarItem(item: item, selected: selected),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({required this.item, required this.selected});

  final _NavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          selected ? item.activeIcon : item.icon,
          color: selected ? AppColors.primary : AppColors.textSecondary,
          size: 24,
        ),
        const SizedBox(height: 3),
        Text(
          item.label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: selected ? 20 : 0,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
