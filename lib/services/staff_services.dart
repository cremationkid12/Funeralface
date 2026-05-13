import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/network/api_client.dart';

class StaffServices {
  StaffServices(this._apiClient);

  final ApiClient _apiClient;

  static const List<String> roles = <String>['user', 'admin'];

  Future<List<dynamic>> listStaff({String? bearerToken}) async {
    final response = await _apiClient.getJson(
      '/v1/staff',
      bearerToken: bearerToken,
    );
    return response['items'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> getMyProfile({String? bearerToken}) {
    return _apiClient.getJson('/v1/staff/me', bearerToken: bearerToken);
  }

  Future<Map<String, dynamic>> updateMyProfile({
    required Map<String, dynamic> payload,
    String? bearerToken,
  }) {
    return _apiClient.patchJson(
      '/v1/staff/me',
      body: payload,
      bearerToken: bearerToken,
    );
  }

  Future<String> uploadMyProfileImage({
    required String bearerToken,
    required Uint8List bytes,
    required String fileName,
    required String staffId,
  }) {
    return uploadStaffPhoto(
      bearerToken: bearerToken,
      bytes: bytes,
      fileName: fileName,
      referenceId: staffId,
    );
  }

  /// Uploads a staff photo to storage. [referenceId] is optional (folder segment);
  /// omit for new staff before a row exists.
  Future<String> uploadStaffPhoto({
    required String bearerToken,
    required Uint8List bytes,
    required String fileName,
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
    request.fields['purpose'] = 'staff_photo';
    final ref = referenceId?.trim();
    if (ref != null && ref.isNotEmpty) {
      request.fields['reference_id'] = ref;
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

  Future<Map<String, dynamic>> createStaff({
    required Map<String, dynamic> payload,
    String? bearerToken,
  }) {
    return _apiClient.postJson(
      '/v1/staff',
      body: payload,
      bearerToken: bearerToken,
    );
  }

  Future<Map<String, dynamic>> updateStaff({
    required String id,
    required Map<String, dynamic> payload,
    String? bearerToken,
  }) {
    return _apiClient.patchJson(
      '/v1/staff/$id',
      body: payload,
      bearerToken: bearerToken,
    );
  }

  Future<void> deleteStaff({required String id, String? bearerToken}) {
    return _apiClient.delete('/v1/staff/$id', bearerToken: bearerToken);
  }

  Future<Map<String, dynamic>> activateStaff({
    required String id,
    String? bearerToken,
  }) {
    return _apiClient.postJson(
      '/v1/staff/$id/activate',
      body: const <String, dynamic>{},
      bearerToken: bearerToken,
    );
  }

  Future<Map<String, dynamic>> deactivateStaff({
    required String id,
    String? bearerToken,
  }) {
    return _apiClient.postJson(
      '/v1/staff/$id/deactivate',
      body: const <String, dynamic>{},
      bearerToken: bearerToken,
    );
  }

  /// Requires admin JWT; backend sends invite email via SendGrid.
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

  Map<String, dynamic> _tryDecodeJson(String body) {
    if (body.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return const {};
  }
}
