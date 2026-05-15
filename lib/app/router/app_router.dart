import 'package:everroute/ui/screens/assignments/assignments_screen.dart';
import 'package:everroute/ui/screens/assignments/assignment_detail_screen.dart';
import 'package:everroute/ui/screens/auth/auth_screen.dart';
import 'package:everroute/ui/screens/auth/forgot_password_screen.dart';
import 'package:everroute/ui/screens/auth/reset_password_screen.dart';
import 'package:everroute/ui/screens/auth/verification_code_screen.dart';
import 'package:everroute/ui/screens/dashboard/dashboard_screen.dart';
import 'package:everroute/features/session/auth_session.dart';
import 'package:everroute/ui/screens/settings/settings_screen.dart';
import 'package:everroute/ui/screens/splash/splash_screen.dart';
import 'package:everroute/ui/screens/staff/staff_detail_screen.dart';
import 'package:everroute/ui/screens/staff/staff_screen.dart';
import 'package:everroute/ui/screens/main_shell.dart';
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
      final isAuth = path == '/auth' || path.startsWith('/auth/');
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
        routes: [
          GoRoute(
            path: 'forgot-password',
            name: 'auth_forgot_password',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: 'verify-code',
            name: 'auth_verify_code',
            builder: (context, state) => const VerificationCodeScreen(),
          ),
          GoRoute(
            path: 'reset-password',
            name: 'auth_reset_password',
            builder: (context, state) {
              String? accessToken;
              String? refreshToken;
              final extra = state.extra;
              if (extra is Map) {
                accessToken = extra['access_token'] as String?;
                refreshToken = extra['refresh_token'] as String?;
              }
              return ResetPasswordScreen(
                recoveryAccessToken: accessToken,
                recoveryRefreshToken: refreshToken,
              );
            },
          ),
        ],
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
                pageBuilder: (context, state) =>
                    const NoTransitionPage<void>(child: DashboardScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/assignments',
                name: 'assignments',
                pageBuilder: (context, state) =>
                    const NoTransitionPage<void>(child: AssignmentsScreen()),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: 'assignment_detail',
                    builder: (context, state) {
                      final extra = state.extra;
                      final map = extra is Map<String, dynamic>
                          ? extra
                          : const <String, dynamic>{};
                      final id = state.pathParameters['id'] ?? '';
                      return AssignmentDetailScreen(
                        assignmentId: id,
                        initial: map,
                      );
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
                pageBuilder: (context, state) =>
                    const NoTransitionPage<void>(child: StaffScreen()),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: 'staff_detail',
                    builder: (context, state) {
                      final extra = state.extra;
                      final map = extra is Map<String, dynamic>
                          ? extra
                          : const <String, dynamic>{};
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
                pageBuilder: (context, state) =>
                    const NoTransitionPage<void>(child: SettingsScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
