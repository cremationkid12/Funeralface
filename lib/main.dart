import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:funeralface_mobile/app/app_repositories.dart';
import 'package:funeralface_mobile/app/funeralface_app.dart';
import 'package:funeralface_mobile/app/router/app_router.dart';
import 'package:funeralface_mobile/core/deeplink/deeplink_coordinator.dart';
import 'package:funeralface_mobile/core/env.dart';
import 'package:funeralface_mobile/core/network/api_client.dart';
import 'package:funeralface_mobile/services/auth_services.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadAppDotenv();
  late final AuthServices authServices;
  final apiClient = ApiClient(
    baseUrl: AppEnv.apiBaseUrl,
    onSessionUnauthorized: () => authServices.clearSession(),
  );
  authServices = AuthServices(apiClient: apiClient);
  await authServices.restoreSession();
  final router = createAppRouter();
  final deeplinkCoordinator = DeeplinkCoordinator(
    router: router,
    expectedHost: AppEnv.deeplinkHost,
  );
  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiClient>.value(value: apiClient),
        RepositoryProvider<AppRepositories>.value(
          value: AppRepositories(apiClient: apiClient),
        ),
      ],
      child: FuneralfaceApp(routerConfig: router),
    ),
  );
  deeplinkCoordinator.start();
}
