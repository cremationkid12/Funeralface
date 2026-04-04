import 'package:funeralface_mobile/core/network/api_client.dart';

/// Creates org + admin staff in the API DB for this Supabase user (mobile never calls POST /v1/auth/login).
Future<void> ensureBackendProvisioned(ApiClient api, String accessToken) async {
  await api.postJson(
    '/v1/auth/ensure-provisioned',
    body: <String, dynamic>{},
    bearerToken: accessToken,
  );
}
