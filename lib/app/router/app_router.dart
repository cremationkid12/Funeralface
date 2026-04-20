import 'package:funeralface_mobile/ui/screens/assignments/assignments_screen.dart';
import 'package:funeralface_mobile/ui/screens/assignments/assignment_detail_screen.dart';
import 'package:funeralface_mobile/ui/screens/auth/auth_screen.dart';
import 'package:funeralface_mobile/ui/screens/dashboard/dashboard_screen.dart';
import 'package:funeralface_mobile/features/session/auth_session.dart';
import 'package:funeralface_mobile/ui/screens/assignments/family_assignment_screen.dart';
import 'package:funeralface_mobile/ui/screens/settings/settings_screen.dart';
import 'package:funeralface_mobile/ui/screens/splash/splash_screen.dart';
import 'package:funeralface_mobile/ui/screens/staff/staff_detail_screen.dart';
import 'package:funeralface_mobile/ui/screens/staff/staff_screen.dart';
import 'package:funeralface_mobile/ui/screens/main_shell.dart';
import 'package:go_router/go_router.dart';

/// Staff shell routes + family deep-link route (`/family/:token`).
GoRouter createAppRouter({String initialLocation = '/splash'}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: AuthSession.instance,
    redirect: (context, state) {
      final path = state.uri.path;
      final authed = AuthSession.instance.isAuthenticated;
      final isFamily = path.startsWith('/family/');
      final isAuth = path == '/auth';
      final isSplash = path == '/splash';
      if (isFamily || isSplash) return null;
      if (!authed && !isAuth) return '/auth';
      if (authed && isAuth) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/family/:token',
        name: 'family_by_token',
        builder: (context, state) {
          final encoded = state.pathParameters['token'] ?? '';
          final token = Uri.decodeComponent(encoded);
          return FamilyAssignmentScreen(token: token);
        },
      ),
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
                routes: [
                  GoRoute(
                    path: ':id',
                    name: 'assignment_detail',
                    builder: (context, state) {
                      final extra = state.extra;
                      final map = extra is Map<String, dynamic> ? extra : const <String, dynamic>{};
                      final id = state.pathParameters['id'] ?? '';
                      return AssignmentDetailScreen(assignmentId: id, initial: map);
                    },
                  ),
                ],
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
                routes: [
                  GoRoute(
                    path: ':id',
                    name: 'staff_detail',
                    builder: (context, state) {
                      final extra = state.extra;
                      final map = extra is Map<String, dynamic> ? extra : const <String, dynamic>{};
                      final id = state.pathParameters['id'] ?? '';
                      return StaffDetailScreen(staffId: id, initial: map);
                    },
                  ),
                ],
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
