import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:everroute/app/app_repositories.dart';
import 'package:everroute/core/network/api_client.dart';
import 'package:everroute/features/auth/auth_cubit.dart';
import 'package:everroute/features/dashboard/dashboard_cubit.dart';
import 'package:everroute/features/notifications/notifications_cubit.dart';
import 'package:everroute/features/staff/staff_cubit.dart';
import 'package:everroute/services/auth_services.dart';
import 'package:everroute/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FuneralfaceApp extends StatelessWidget {
  const FuneralfaceApp({super.key, required this.routerConfig});

  final GoRouter routerConfig;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(
            authServices: AuthServices(apiClient: context.read<ApiClient>()),
            googleSignIn: GoogleSignIn.instance,
          ),
        ),
        BlocProvider<StaffCubit>(
          create: (context) =>
              StaffCubit(staffServices: context.read<AppRepositories>().staff),
        ),
        BlocProvider<DashboardCubit>(
          create: (context) => DashboardCubit(
            staffServices: context.read<AppRepositories>().staff,
            assignmentsServices: context.read<AppRepositories>().assignments,
            apiClient: context.read<ApiClient>(),
          ),
        ),
        BlocProvider<NotificationsCubit>(
          create: (context) => NotificationsCubit(
            notificationsServices: context.read<AppRepositories>().notifications,
          ),
        ),
      ],
      child: MaterialApp.router(
        title: 'Everroute',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        routerConfig: routerConfig,
      ),
    );
  }
}
