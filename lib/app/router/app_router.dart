import 'package:funeralface_mobile/features/assignments/assignments_screen.dart';
import 'package:funeralface_mobile/features/dashboard/dashboard_screen.dart';
import 'package:funeralface_mobile/features/settings/settings_screen.dart';
import 'package:funeralface_mobile/features/staff/staff_screen.dart';
import 'package:funeralface_mobile/shell/main_shell.dart';
import 'package:go_router/go_router.dart';

/// Staff app routes (P4.1 routing baseline; P5 extends with family token route).
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                name: 'dashboard',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: DashboardScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/assignments',
                name: 'assignments',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: AssignmentsScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/staff',
                name: 'staff',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: StaffScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: SettingsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
