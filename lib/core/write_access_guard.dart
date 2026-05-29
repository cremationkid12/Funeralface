import 'package:everroute/app/app_repositories.dart';
import 'package:everroute/core/network/api_client.dart';
import 'package:everroute/core/theme/app_theme.dart';
import 'package:everroute/features/session/staff_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Loads the signed-in staff role (`admin` or `user`).
Future<String?> loadMyRole(BuildContext context) async {
  final bearer = staffBearerToken();
  if (bearer == null) return null;
  try {
    final profile = await context
        .read<AppRepositories>()
        .staff
        .getMyProfile(bearerToken: bearer);
    final role = profile['role']?.toString().trim().toLowerCase();
    return role == 'admin' ? 'admin' : 'user';
  } catch (_) {
    return null;
  }
}

Future<bool> _orgIsSubscribed(BuildContext context) async {
  final bearer = staffBearerToken();
  if (bearer == null) return false;
  try {
    final sub = await context
        .read<AppRepositories>()
        .billing
        .getSubscription(bearerToken: bearer);
    return sub.isSubscribed;
  } catch (_) {
    return false;
  }
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
        'Subscribe in Settings → Payment to continue making changes.',
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

Future<void> _showPermissionDeniedDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        'Permission denied',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: Text(
        'You do not have permission to perform this action. '
        'Contact your funeral home admin.',
        style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Org must have trialing/active subscription (all roles).
Future<bool> ensureOrgIsSubscribed(BuildContext context) async {
  if (await _orgIsSubscribed(context)) return true;
  if (!context.mounted) return false;
  await _showSubscriptionRequiredDialog(context);
  return false;
}

/// Admin + active subscription required for create/update/delete (except billing).
Future<bool> ensureAdminWriteAccess(
  BuildContext context, {
  bool? isAdmin,
}) async {
  final admin = isAdmin ?? (await loadMyRole(context)) == 'admin';
  if (!admin) {
    if (!context.mounted) return false;
    await _showPermissionDeniedDialog(context);
    return false;
  }
  if (!context.mounted) return false;
  return ensureOrgIsSubscribed(context);
}

/// Shows a dialog for API write failures when the backend blocks the action.
Future<void> showWriteAccessApiError(BuildContext context, ApiException error) async {
  if (!context.mounted) return;
  if (error.code == 'subscription_required') {
    await _showSubscriptionRequiredDialog(context);
    return;
  }
  if (error.code == 'forbidden') {
    await _showPermissionDeniedDialog(context);
    return;
  }
}
