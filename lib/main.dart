import 'package:flutter/material.dart';
import 'package:funeralface_mobile/app/app_repositories.dart';
import 'package:funeralface_mobile/app/funeralface_app.dart';
import 'package:funeralface_mobile/app/router/app_router.dart';
import 'package:funeralface_mobile/core/deeplink/deeplink_coordinator.dart';
import 'package:funeralface_mobile/core/env.dart';
import 'package:funeralface_mobile/core/network/api_client.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final apiClient = ApiClient(baseUrl: AppEnv.apiBaseUrl);
  final router = createAppRouter();
  final deeplinkCoordinator = DeeplinkCoordinator(
    router: router,
    expectedHost: AppEnv.deeplinkHost,
  );
  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: apiClient),
        Provider.value(value: AppRepositories(apiClient: apiClient)),
      ],
      child: FuneralfaceApp(routerConfig: router),
    ),
  );
  deeplinkCoordinator.start();
}
