import 'package:flutter/material.dart';

import 'core/env.dart';
import 'core/network/api_client.dart';
import 'features/assignments/assignments_repository.dart';
import 'features/dashboard/dashboard_usecase.dart';
import 'features/settings/settings_repository.dart';
import 'features/staff/staff_repository.dart';

void main() {
  runApp(const FuneralfaceApp());
}

class FuneralfaceApp extends StatelessWidget {
  const FuneralfaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Funeralface',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF78716C)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient(baseUrl: AppEnv.apiBaseUrl);
    final settingsRepository = SettingsRepository(apiClient);
    final dashboardUseCase = DashboardUseCase(
      staffRepository: StaffRepository(apiClient),
      assignmentsRepository: AssignmentsRepository(apiClient),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Funeralface'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phase 2 — mobile foundation',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'API base URL (from dart-define):',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            SelectableText(
              AppEnv.apiBaseUrl,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text('APP_ENV: ${AppEnv.appEnv}'),
            Text('FLAVOR: ${AppEnv.flavor}'),
            Text('DEEPLINK_HOST: ${AppEnv.deeplinkHost}'),
            const SizedBox(height: 16),
            Text('API client base URL: ${apiClient.baseUrl}'),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: settingsRepository.getSettings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Loading settings...');
                }
                if (snapshot.hasError) {
                  return Text('Settings error: ${snapshot.error}');
                }
                final data = snapshot.data ?? const <String, dynamic>{};
                final name = data['funeral_home_name']?.toString() ?? '';
                return Text('Settings loaded: ${name.isEmpty ? "(empty)" : name}');
              },
            ),
            const SizedBox(height: 12),
            FutureBuilder<DashboardSummary>(
              future: dashboardUseCase.loadSummary(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Loading dashboard summary...');
                }
                if (snapshot.hasError) {
                  return Text('Dashboard error: ${snapshot.error}');
                }
                final summary = snapshot.data;
                if (summary == null) {
                  return const Text('No dashboard data');
                }
                return Text(
                  'Staff: ${summary.staffCount}, '
                  'Active assignments: ${summary.activeAssignments}, '
                  'Completed: ${summary.completedAssignments}',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
