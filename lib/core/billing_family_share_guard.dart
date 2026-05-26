import 'package:everroute/app/app_repositories.dart';
import 'package:everroute/core/theme/app_theme.dart';
import 'package:everroute/features/session/staff_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Blocks family link copy/create/email when the org has no active subscription
/// (free trial ended or billing inactive).
Future<bool> ensureSubscriptionAllowsFamilyShare(BuildContext context) async {
  final bearer = staffBearerToken();
  if (bearer == null) return false;

  try {
    final sub = await context
        .read<AppRepositories>()
        .billing
        .getSubscription(bearerToken: bearer);
    if (sub.isSubscribed) return true;
  } catch (_) {
    if (!context.mounted) return false;
    await _showSubscriptionRequiredDialog(context);
    return false;
  }

  if (!context.mounted) return false;
  await _showSubscriptionRequiredDialog(context);
  return false;
}

Future<void> _showSubscriptionRequiredDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        'Subscription required',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: Text(
        'Your free trial has ended or your subscription is inactive. '
        'Subscribe in Settings → Payment to create or share family links.',
        style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            dialogContext.go('/settings');
          },
          child: const Text('Go to Payment'),
        ),
      ],
    ),
  );
}
