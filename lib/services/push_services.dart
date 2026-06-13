import 'package:everroute/core/network/api_client.dart';

class PushServices {
  PushServices(this._apiClient);

  final ApiClient _apiClient;

  Future<void> register({
    required String bearerToken,
    required String fcmToken,
    required String platform,
  }) async {
    await _apiClient.postJson(
      '/v1/push/register',
      body: <String, dynamic>{
        'fcm_token': fcmToken,
        'platform': platform,
      },
      bearerToken: bearerToken,
    );
  }

  Future<void> unregister({
    required String bearerToken,
    String? fcmToken,
  }) async {
    await _apiClient.deleteJson(
      '/v1/push/register',
      body: fcmToken == null || fcmToken.isEmpty
          ? const <String, dynamic>{}
          : <String, dynamic>{'fcm_token': fcmToken},
      bearerToken: bearerToken,
    );
  }
}
