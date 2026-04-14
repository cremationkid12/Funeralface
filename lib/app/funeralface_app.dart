import 'package:flutter/material.dart';
import 'package:funeralface_mobile/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class FuneralfaceApp extends StatelessWidget {
  const FuneralfaceApp({super.key, required this.routerConfig});

  final GoRouter routerConfig;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EverRoute',
      theme: AppTheme.light,
      routerConfig: routerConfig,
    );
  }
}
