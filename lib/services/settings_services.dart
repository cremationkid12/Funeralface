import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/network/api_client.dart';

class SettingsServices {
  SettingsServices(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getSettings({String? bearerToken}) {
    return _apiClient.getJson('/v1/settings', bearerToken: bearerToken);
  }

  Future<Map<String, dynamic>> updateSettings(
    Map<String, dynamic> payload, {
    String? bearerToken,
  }) {
    return _apiClient.patchJson(
      '/v1/settings',
      body: payload,
      bearerToken: bearerToken,
    );
  }

  Future<String> uploadImageAsset({
    required String bearerToken,
    required Uint8List bytes,
    required String fileName,
    required String purpose,
    String? referenceId,
  }) async {
    final normalizedBase = _apiClient.baseUrl.trim().replaceAll(
      RegExp(r'/+$'),
      '',
    );
    final uploadUrl = '$normalizedBase/v1/uploads/image';
    if (bytes.isEmpty) {
      throw StateError('Image file is empty.');
    }

    final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
    request.headers['Authorization'] = 'Bearer $bearerToken';
    request.fields['purpose'] = purpose;
    final normalizedReference = referenceId?.trim() ?? '';
    if (normalizedReference.isNotEmpty) {
      request.fields['reference_id'] = normalizedReference;
    }
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final responseMap = _tryDecodeJson(response.body);
      final message =
          responseMap['message']?.toString() ??
          responseMap['error_description']?.toString() ??
          responseMap['error']?.toString() ??
          'Upload failed (${response.statusCode})';
      throw StateError('$message (POST $uploadUrl)');
    }

    final responseMap = _tryDecodeJson(response.body);
    final publicUrl = responseMap['public_url']?.toString().trim() ?? '';
    if (publicUrl.isEmpty) {
      throw StateError('Upload succeeded but no public URL was returned.');
    }
    return publicUrl;
  }

  Map<String, dynamic> _tryDecodeJson(String body) {
    if (body.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return const {};
  }
}
