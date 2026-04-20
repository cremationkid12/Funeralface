import '../core/network/api_client.dart';

class AssignmentsServices {
  AssignmentsServices(this._apiClient);

  final ApiClient _apiClient;

  static const List<String> statuses = <String>[
    'pending',
    'assigned',
    'en_route',
    'arrived',
    'completed',
    'cancelled',
  ];

  Future<List<dynamic>> listAssignments({String? bearerToken}) async {
    final response = await _apiClient.getJson(
      '/v1/assignments?sort=-created_at',
      bearerToken: bearerToken,
    );
    return response['items'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> createAssignment({
    required Map<String, dynamic> payload,
    String? bearerToken,
  }) {
    return _apiClient.postJson(
      '/v1/assignments',
      body: payload,
      bearerToken: bearerToken,
    );
  }

  Future<Map<String, dynamic>> updateAssignment({
    required String assignmentId,
    required Map<String, dynamic> payload,
    String? bearerToken,
  }) {
    return _apiClient.patchJson(
      '/v1/assignments/$assignmentId',
      body: payload,
      bearerToken: bearerToken,
    );
  }
}
