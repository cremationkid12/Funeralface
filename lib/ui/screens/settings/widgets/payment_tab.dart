import 'package:flutter/material.dart';
import 'package:everroute/core/theme/app_theme.dart';
import 'package:everroute/models/billing_subscription_model.dart';
import 'package:everroute/ui/widgets/app_buttons.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentTab extends StatelessWidget {
  const PaymentTab({
    super.key,
    required this.subscription,
    required this.loading,
    required this.actionBusy,
    required this.isAdmin,
    required this.error,
    required this.onRefresh,
    required this.onSubscribe,
    required this.onManageBilling,
  });

  final BillingSubscriptionModel? subscription;
  final bool loading;
  final bool actionBusy;
  final bool isAdmin;
  final String? error;
  final VoidCallback onRefresh;
  final VoidCallback onSubscribe;
  final VoidCallback onManageBilling;

  @override
  Widget build(BuildContext context) {
    if (loading && subscription == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final sub = subscription;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        if (error != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.statusCancelledBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              error!,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.statusCancelledFg,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'EverRoute subscription',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                sub?.planLabel ?? '\$11.99/mo',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                sub?.isAppTrial == true
                    ? 'Your ${sub?.trialDays ?? 7}-day free trial is active. '
                          'Subscribe before it ends to keep full access.'
                    : '${sub?.trialDays ?? 7}-day free trial, then billed monthly.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              if (sub?.isAppTrial == true &&
                  sub?.trialDaysRemaining != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${sub!.trialDaysRemaining} day${sub.trialDaysRemaining == 1 ? '' : 's'} left in your free trial.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _StatusRow(
                label: 'Status',
                value: sub?.statusLabel ?? '—',
                highlight: sub?.isSubscribed == true,
              ),
              if (sub?.trialEndsAt != null) ...[
                const SizedBox(height: 10),
                _StatusRow(
                  label: 'Trial ends',
                  value: _formatDate(sub!.trialEndsAt!),
                ),
              ],
              if (sub?.currentPeriodEnd != null) ...[
                const SizedBox(height: 10),
                _StatusRow(
                  label: 'Current period ends',
                  value: _formatDate(sub!.currentPeriodEnd!),
                ),
              ],
              if (sub?.cancelAtPeriodEnd == true) ...[
                const SizedBox(height: 12),
                Text(
                  'Subscription will cancel at the end of the current period.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.statusPendingFg,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!isAdmin)
          Text(
            'Only admins can start or manage billing for this funeral home.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          )
        else if (sub != null && sub.isAppTrial) ...[
          AppPrimaryButton(
            label: actionBusy ? 'Opening checkout…' : 'Subscribe before trial ends',
            onPressed: actionBusy ? null : onSubscribe,
          ),
          const SizedBox(height: 10),
          Text(
            'Optional now — your free trial already includes full app access. '
            'Add a payment method in Stripe when you are ready.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ] else if (sub != null && !sub.isSubscribed) ...[
          AppPrimaryButton(
            label: actionBusy ? 'Opening checkout…' : 'Subscribe',
            onPressed: actionBusy ? null : onSubscribe,
          ),
          const SizedBox(height: 10),
          Text(
            'You will complete payment securely in Stripe Checkout.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ] else if (sub != null && sub.isSubscribed) ...[
          AppAccentButton(
            label: actionBusy ? 'Opening portal…' : 'Manage subscription',
            onPressed: actionBusy ? null : onManageBilling,
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: loading || actionBusy ? null : onRefresh,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(
            'Refresh status',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year;
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: highlight ? AppColors.accentSurface : AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: highlight ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
