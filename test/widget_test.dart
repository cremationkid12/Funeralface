import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funeralface_mobile/app/app_repositories.dart';
import 'package:funeralface_mobile/app/funeralface_app.dart';
import 'package:funeralface_mobile/app/router/app_router.dart';
import 'package:funeralface_mobile/app/session/auth_session.dart';
import 'package:funeralface_mobile/core/network/api_client.dart';
import 'package:provider/provider.dart';

import 'support/mock_api_client.dart';

void main() {
  setUp(() {
    // Ticket 5 removes the DEV_AUTH_BEARER_TOKEN fallback; widget tests must
    // provide an authenticated session for protected staff screens.
    AuthSession.instance.setSession(accessToken: 'test-access-token', userId: 'user-1');
  });

  tearDown(() {
    AuthSession.instance.clear();
  });

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

  testWidgets('Dashboard shows summary cards and recent assignments', (WidgetTester tester) async {
    final api = ApiClient(
      baseUrl: 'http://localhost:8010',
      httpClient: mockDashboardHttpClient(),
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

    expect(find.text('Staff'), findsWidgets);
    expect(find.text('2'), findsWidgets);
    expect(find.text('Active assignments'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Recent assignments'), findsOneWidget);
    expect(find.text('John Doe'), findsOneWidget);
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

  testWidgets('Assignments create dialog adds a new item to list', (WidgetTester tester) async {
    final api = ApiClient(
      baseUrl: 'http://localhost:8010',
      httpClient: mockAssignmentsCrudHttpClient(),
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
    await tester.tap(find.text('Assignments'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Create assignment'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Decedent name'), 'Alice Doe');
    await tester.enterText(find.widgetWithText(TextFormField, 'Pickup address'), '42 Test St');
    await tester.enterText(find.widgetWithText(TextFormField, 'Contact name'), 'Bob');
    await tester.enterText(find.widgetWithText(TextFormField, 'Contact phone'), '777');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Alice Doe'), findsOneWidget);
  });

  testWidgets('Assignments status update reflects in list', (WidgetTester tester) async {
    final api = ApiClient(
      baseUrl: 'http://localhost:8010',
      httpClient: mockAssignmentsCrudHttpClient(),
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
    await tester.tap(find.text('Assignments'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('en_route').last);
    await tester.pumpAndSettle();

    expect(find.text('en_route'), findsWidgets);
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

    await tester.tap(find.text('Staff').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jane Staff'));
    await tester.pumpAndSettle();

    expect(find.text('Staff member'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
  });

  testWidgets('Staff create dialog adds a new staff item to list', (WidgetTester tester) async {
    final api = ApiClient(
      baseUrl: 'http://localhost:8010',
      httpClient: mockStaffCrudHttpClient(),
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
    await tester.tap(find.text('Staff').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add staff member'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'New Staff');
    await tester.enterText(find.widgetWithText(TextFormField, 'Phone'), '999');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('New Staff'), findsOneWidget);
  });

  testWidgets('Staff invite dialog submits email', (WidgetTester tester) async {
    final api = ApiClient(
      baseUrl: 'http://localhost:8010',
      httpClient: mockStaffCrudHttpClient(),
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
    await tester.tap(find.text('Staff').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Invite by email (admin + Supabase)'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'invite@example.com');
    await tester.tap(find.text('Send invite'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Invite sent'), findsOneWidget);
  });

  testWidgets('Staff screen shows admin-required message on 403', (WidgetTester tester) async {
    final api = ApiClient(
      baseUrl: 'http://localhost:8010',
      httpClient: mockStaffAppHttpClientWithStaffListForbidden(),
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
    await tester.tap(find.text('Staff').last);
    await tester.pumpAndSettle();

    expect(find.text('Admin role required to manage staff.'), findsOneWidget);
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
