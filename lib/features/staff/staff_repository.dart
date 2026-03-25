import '../../core/network/api_client.dart';

class StaffRepository {
  StaffRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<dynamic>> listStaff({String? bearerToken}) async {
    final response = await _apiClient.getJson('/v1/staff', bearerToken: bearerToken);
    return response['items'] as List<dynamic>? ?? const [];
  }
}
