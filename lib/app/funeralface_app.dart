import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:funeralface_mobile/app/app_repositories.dart';
import 'package:funeralface_mobile/core/network/api_client.dart';
import 'package:funeralface_mobile/features/auth/auth_cubit.dart';
import 'package:funeralface_mobile/features/staff/staff_cubit.dart';
import 'package:funeralface_mobile/services/auth_services.dart';
import 'package:funeralface_mobile/core/theme/app_theme.dart';
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
      ],
      child: MaterialApp.router(
        title: 'Everroute',
        theme: AppTheme.light,
        routerConfig: routerConfig,
      ),
    );
  }
}
