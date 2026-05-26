import '../core/network/api_client.dart';
import '../models/billing_subscription_model.dart';

class BillingServices {
  BillingServices(this._apiClient);

  final ApiClient _apiClient;

  Future<BillingSubscriptionModel> getSubscription({required String bearerToken}) async {
    final json = await _apiClient.getJson(
      '/v1/billing/subscription',
      bearerToken: bearerToken,
    );
    return BillingSubscriptionModel.fromJson(json);
  }

  Future<String> createCheckoutSession({required String bearerToken}) async {
    final json = await _apiClient.postJson(
      '/v1/billing/checkout-session',
      body: const <String, dynamic>{},
      bearerToken: bearerToken,
    );
    final url = json['checkout_url']?.toString().trim() ?? '';
    if (url.isEmpty) {
      throw StateError('Checkout URL was not returned.');
    }
    return url;
  }

  Future<String> createPortalSession({required String bearerToken}) async {
    final json = await _apiClient.postJson(
      '/v1/billing/portal-session',
      body: const <String, dynamic>{},
      bearerToken: bearerToken,
    );
    final url = json['portal_url']?.toString().trim() ?? '';
    if (url.isEmpty) {
      throw StateError('Billing portal URL was not returned.');
    }
    return url;
  }
}
