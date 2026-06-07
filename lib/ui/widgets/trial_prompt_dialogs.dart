import 'package:everroute/core/theme/app_theme.dart';
import 'package:everroute/models/billing_subscription_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> showTrialWelcomeDialog(
  BuildContext context, {
  required BillingSubscriptionModel subscription,
}) {
  final days = subscription.trialDaysRemaining ?? subscription.trialDays;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        'Your free trial has started',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: Text(
        'Welcome to EverRoute! You have $days days of full access to manage '
        'assignments, staff, and funeral home settings at no charge. '
        'When you are ready, subscribe in Settings → Payment before your trial ends.',
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}

Future<void> showTrialExpiringSoonDialog(
  BuildContext context, {
  required BillingSubscriptionModel subscription,
}) {
  final days = subscription.trialDaysRemaining ?? 1;
  final dayLabel = days == 1 ? '1 day' : '$days days';
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        'Free trial ending soon',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: Text(
        'Your free trial ends in $dayLabel. Subscribe in Settings → Payment '
        'to keep using assignments, staff management, and family links.',
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Later'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            if (context.mounted) {
              context.go('/settings?billing=payment');
            }
          },
          child: const Text('Go to Payment'),
        ),
      ],
    ),
  );
}
