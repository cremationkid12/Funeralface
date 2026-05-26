class BillingSubscriptionModel {
  const BillingSubscriptionModel({
    required this.orgId,
    required this.status,
    required this.planAmountCents,
    required this.planInterval,
    required this.trialDays,
    required this.isSubscribed,
    required this.cancelAtPeriodEnd,
    this.trialEndsAt,
    this.currentPeriodEnd,
  });

  final String orgId;
  final String status;
  final int planAmountCents;
  final String planInterval;
  final int trialDays;
  final bool isSubscribed;
  final bool cancelAtPeriodEnd;
  final DateTime? trialEndsAt;
  final DateTime? currentPeriodEnd;

  factory BillingSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return BillingSubscriptionModel(
      orgId: json['org_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'none',
      planAmountCents: (json['plan_amount_cents'] as num?)?.toInt() ?? 1199,
      planInterval: json['plan_interval']?.toString() ?? 'month',
      trialDays: (json['trial_days'] as num?)?.toInt() ?? 7,
      isSubscribed: json['is_subscribed'] == true,
      cancelAtPeriodEnd: json['cancel_at_period_end'] == true,
      trialEndsAt: _parseDate(json['trial_ends_at']),
      currentPeriodEnd: _parseDate(json['current_period_end']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String get planLabel {
    final dollars = (planAmountCents / 100).toStringAsFixed(2);
    return '\$$dollars/${planInterval == 'month' ? 'mo' : planInterval}';
  }

  String get statusLabel {
    switch (status) {
      case 'trialing':
        return 'Free trial';
      case 'active':
        return 'Active';
      case 'past_due':
        return 'Past due';
      case 'canceled':
        return 'Canceled';
      case 'unpaid':
        return 'Unpaid';
      case 'incomplete':
        return 'Incomplete';
      default:
        return 'Not subscribed';
    }
  }
}
