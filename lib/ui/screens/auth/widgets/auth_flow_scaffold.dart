import 'package:everroute/ui/screens/auth/widgets/auth_section_card.dart';
import 'package:flutter/material.dart';
import 'package:everroute/core/theme/app_theme.dart';
import 'package:everroute/ui/widgets/everroute_back_button.dart';

class AuthFlowScaffold extends StatelessWidget {
  const AuthFlowScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    this.onBack,
    this.showBackButton = true,
    this.scrollHeader,
    this.belowBody,
  });

  final String title;
  final String subtitle;
  final Widget body;
  final VoidCallback? onBack;

  /// When false, hides [EverrouteBackButton] (e.g. login / signup root screen).
  final bool showBackButton;

  /// Shown above the heading card inside the scroll view (e.g. logo).
  final Widget? scrollHeader;

  /// Placed below the body card after a gap (e.g. social login block).
  final Widget? belowBody;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (scrollHeader != null) ...[
                scrollHeader!,
                const SizedBox(height: 24),
              ],
              AuthSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showBackButton) ...[
                      EverrouteBackButton(
                        onPressed: onBack ??
                            () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AuthSectionCard(child: body),
              if (belowBody != null) ...[
                const SizedBox(height: 16),
                belowBody!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
