import '../../core/network/api_client.dart';

class StaffRepository {
  StaffRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<dynamic>> listStaff({String? bearerToken}) async {
    final response = await _apiClient.getJson('/v1/staff', bearerToken: bearerToken);
    return response['items'] as List<dynamic>? ?? const [];
  }

  /// Requires admin JWT; backend sends Supabase invite email.
  Future<Map<String, dynamic>> inviteByEmail({
    required String email,
    String? bearerToken,
  }) {
    return _apiClient.postJson(
      '/v1/staff/invite',
      body: {'email': email.trim()},
      bearerToken: bearerToken,
    );
  }
}
