import 'package:flutter/material.dart';

import 'core/env.dart';

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
              'Phase 1 — API contract prep',
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
            Text('DEEPLINK_HOST: ${AppEnv.deeplinkHost}'),
          ],
        ),
      ),
    );
  }
}
