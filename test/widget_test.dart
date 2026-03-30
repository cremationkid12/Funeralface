import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funeralface_mobile/app/app_repositories.dart';
import 'package:funeralface_mobile/app/funeralface_app.dart';
import 'package:funeralface_mobile/app/router/app_router.dart';
import 'package:provider/provider.dart';

import 'support/mock_api_client.dart';

void main() {
  testWidgets('App boots with bottom navigation shell', (WidgetTester tester) async {
    final api = mockStaffAppApiClient();
    final router = createAppRouter();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: api),
          Provider.value(value: AppRepositories(apiClient: api)),
        ],
        child: FuneralfaceApp(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);
  });
}
