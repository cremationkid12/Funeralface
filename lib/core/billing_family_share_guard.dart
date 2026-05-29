import 'package:everroute/core/write_access_guard.dart';
import 'package:flutter/material.dart';

/// Blocks family link copy/create/email when the org has no active subscription.
Future<bool> ensureSubscriptionAllowsFamilyShare(BuildContext context) async {
  return ensureOrgIsSubscribed(context);
}
