import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:everroute/app/app_repositories.dart';
import 'package:everroute/app/funeralface_app.dart';
import 'package:everroute/app/router/app_router.dart';
import 'package:everroute/core/deeplink/deeplink_coordinator.dart';
import 'package:everroute/core/app_flavor.dart';
import 'package:everroute/core/env.dart';
import 'package:everroute/core/network/api_client.dart';
import 'package:everroute/services/auth_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    debugPrint('App flavor: ${parseAppFlavor().name}');
  }
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
