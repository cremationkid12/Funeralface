import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({required this.baseUrl, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;

  Uri _uri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final normalizedBase = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$normalizedBase$normalizedPath');
  }

  Map<String, String> _headers({String? bearerToken}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (bearerToken != null && bearerToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $bearerToken';
    }
    return headers;
  }

  Map<String, dynamic> _decode(http.Response response) {
    final body = response.body.isEmpty ? '{}' : response.body;
    return jsonDecode(body) as Map<String, dynamic>;
  }

  void _throwOnError(http.Response response, Map<String, dynamic> decoded) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        code: decoded['code']?.toString(),
        message: decoded['message']?.toString() ?? 'Request failed',
      );
    }
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    String? bearerToken,
  }) async {
    final response = await _httpClient.get(
      _uri(path),
      headers: _headers(bearerToken: bearerToken),
    );
    final decoded = _decode(response);
    _throwOnError(response, decoded);
    return decoded;
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    String? bearerToken,
  }) async {
    final response = await _httpClient.post(
      _uri(path),
      headers: _headers(bearerToken: bearerToken),
      body: jsonEncode(body),
    );
    final decoded = _decode(response);
    _throwOnError(response, decoded);
    return decoded;
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    required Map<String, dynamic> body,
    String? bearerToken,
  }) async {
    final response = await _httpClient.patch(
      _uri(path),
      headers: _headers(bearerToken: bearerToken),
      body: jsonEncode(body),
    );
    final decoded = _decode(response);
    _throwOnError(response, decoded);
    return decoded;
  }

  Future<void> delete(String path, {String? bearerToken}) async {
    final response = await _httpClient.delete(
      _uri(path),
      headers: _headers(bearerToken: bearerToken),
    );
    final decoded = _decode(response);
    _throwOnError(response, decoded);
  }
}

class ApiException implements Exception {
  ApiException({required this.statusCode, required this.message, this.code});

  final int statusCode;
  final String message;
  final String? code;

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, code: ${code ?? '-'}, message: $message)';
}
