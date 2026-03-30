import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FuneralfaceApp extends StatelessWidget {
  const FuneralfaceApp({super.key, required this.routerConfig});

  final GoRouter routerConfig;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Funeralface',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF78716C)),
        useMaterial3: true,
      ),
      routerConfig: routerConfig,
    );
  }
}
