import '../../core/network/api_client.dart';

class StaffRepository {
  StaffRepository(this._apiClient);

  final ApiClient _apiClient;

  static const List<String> roles = <String>['user', 'admin'];

  Future<List<dynamic>> listStaff({String? bearerToken}) async {
    final response = await _apiClient.getJson('/v1/staff', bearerToken: bearerToken);
    return response['items'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> createStaff({
    required Map<String, dynamic> payload,
    String? bearerToken,
  }) {
    return _apiClient.postJson('/v1/staff', body: payload, bearerToken: bearerToken);
  }

  Future<Map<String, dynamic>> updateStaff({
    required String id,
    required Map<String, dynamic> payload,
    String? bearerToken,
  }) {
    return _apiClient.patchJson('/v1/staff/$id', body: payload, bearerToken: bearerToken);
  }

  Future<void> deleteStaff({required String id, String? bearerToken}) {
    return _apiClient.delete('/v1/staff/$id', bearerToken: bearerToken);
  }

  Future<Map<String, dynamic>> activateStaff({required String id, String? bearerToken}) {
    return _apiClient.postJson(
      '/v1/staff/$id/activate',
      body: const <String, dynamic>{},
      bearerToken: bearerToken,
    );
  }

  Future<Map<String, dynamic>> deactivateStaff({required String id, String? bearerToken}) {
    return _apiClient.postJson(
      '/v1/staff/$id/deactivate',
      body: const <String, dynamic>{},
      bearerToken: bearerToken,
    );
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
