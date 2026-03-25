import '../../core/network/api_client.dart';

class AssignmentsRepository {
  AssignmentsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<dynamic>> listAssignments({String? bearerToken}) async {
    final response = await _apiClient.getJson(
      '/v1/assignments?sort=-created_at',
      bearerToken: bearerToken,
    );
    return response['items'] as List<dynamic>? ?? const [];
  }
}
