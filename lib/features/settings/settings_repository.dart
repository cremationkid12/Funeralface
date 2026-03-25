import '../../core/network/api_client.dart';

class SettingsRepository {
  SettingsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getSettings({String? bearerToken}) {
    return _apiClient.getJson('/v1/settings', bearerToken: bearerToken);
  }

  Future<Map<String, dynamic>> updateSettings(
    Map<String, dynamic> payload, {
    String? bearerToken,
  }) {
    return _apiClient.patchJson('/v1/settings', body: payload, bearerToken: bearerToken);
  }
}
