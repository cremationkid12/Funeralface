import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funeralface_mobile/app/app_repositories.dart';
import 'package:funeralface_mobile/app/funeralface_app.dart';
import 'package:funeralface_mobile/app/router/app_router.dart';
import 'package:funeralface_mobile/core/network/api_client.dart';
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

  testWidgets('Assignments list can navigate to detail screen', (WidgetTester tester) async {
    final api = ApiClient(
      baseUrl: 'http://localhost:8010',
      httpClient: mockStaffAppHttpClientWithAssignmentList(),
    );
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

    // Go to assignments tab.
    await tester.tap(find.text('Assignments'));
    await tester.pumpAndSettle();

    // Tap first assignment to open detail.
    await tester.tap(find.text('John Doe'));
    await tester.pumpAndSettle();

    expect(find.text('Assignment'), findsOneWidget);
    expect(find.text('Decedent name'), findsOneWidget);
  });

  testWidgets('Staff list can navigate to detail screen', (WidgetTester tester) async {
    final api = ApiClient(
      baseUrl: 'http://localhost:8010',
      httpClient: mockStaffAppHttpClientWithStaffList(),
    );
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

    await tester.tap(find.text('Staff'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jane Staff'));
    await tester.pumpAndSettle();

    expect(find.text('Staff member'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
  });

  testWidgets('Family deep link route loads public assignment', (WidgetTester tester) async {
    final api = ApiClient(
      baseUrl: 'http://localhost:8010',
      httpClient: mockFamilyTokenHttpClient(),
    );
    final router = createAppRouter(initialLocation: '/family/tok-1');

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

    expect(find.text('Service status'), findsOneWidget);
    expect(find.textContaining('en route'), findsWidgets);
  });
}
