import 'package:flutter/material.dart';
import 'package:funeralface_mobile/app/app_repositories.dart';
import 'package:funeralface_mobile/app/funeralface_app.dart';
import 'package:funeralface_mobile/app/router/app_router.dart';
import 'package:funeralface_mobile/core/deeplink/deeplink_coordinator.dart';
import 'package:funeralface_mobile/core/env.dart';
import 'package:funeralface_mobile/core/network/api_client.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:funeralface_mobile/app/session/auth_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppEnv.hasSupabaseAuthConfig) {
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
    );
    final session = Supabase.instance.client.auth.currentSession;
    AuthSession.instance.setSession(
      accessToken: session?.accessToken,
      userId: session?.user.id,
    );
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      final s = event.session;
      AuthSession.instance.setSession(
        accessToken: s?.accessToken,
        userId: s?.user.id,
      );
    });
  }
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
