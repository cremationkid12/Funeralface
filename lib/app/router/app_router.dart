import 'package:funeralface_mobile/features/assignments/assignments_screen.dart';
import 'package:funeralface_mobile/features/assignments/assignment_detail_screen.dart';
import 'package:funeralface_mobile/features/auth/auth_screen.dart';
import 'package:funeralface_mobile/features/dashboard/dashboard_screen.dart';
import 'package:funeralface_mobile/app/session/auth_session.dart';
import 'package:funeralface_mobile/app/session/staff_auth.dart';
import 'package:funeralface_mobile/core/env.dart';
import 'package:funeralface_mobile/features/family/family_assignment_screen.dart';
import 'package:funeralface_mobile/features/settings/settings_screen.dart';
import 'package:funeralface_mobile/features/staff/staff_detail_screen.dart';
import 'package:funeralface_mobile/features/staff/staff_screen.dart';
import 'package:funeralface_mobile/shell/main_shell.dart';
import 'package:go_router/go_router.dart';

/// Staff shell routes + family deep-link route (`/family/:token`).
GoRouter createAppRouter({String initialLocation = '/dashboard'}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: AuthSession.instance,
    redirect: (context, state) {
      if (!AppEnv.hasSupabaseAuthConfig) return null;
      final path = state.uri.path;
      final authed = (staffBearerToken() ?? '').trim().isNotEmpty;
      final isFamily = path.startsWith('/family/');
      final isAuth = path == '/auth';
      if (isFamily) return null;
      if (!authed && !isAuth) return '/auth';
      if (authed && isAuth) return '/dashboard';
      return null;
    },
    routes: [
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
