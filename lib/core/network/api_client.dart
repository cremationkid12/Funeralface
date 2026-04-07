import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;

  /// Ensures a valid absolute origin: [AppEnv.apiBaseUrl] must include `https://` for Railway,
  /// but we accept bare hosts and default to `https://` (or `http://` for common local dev hosts).
  String _normalizedBase() {
    var b = baseUrl.trim();
    if (b.isEmpty) return b;
    b = b.replaceAll(RegExp(r'/+$'), '');
    if (RegExp(r'^[a-zA-Z][\w+.-]*://').hasMatch(b)) return b;
    final lower = b.toLowerCase();
    if (lower.startsWith('localhost') ||
        lower.startsWith('127.0.0.1') ||
        lower.startsWith('10.0.2.2') ||
        lower.startsWith('0.0.0.0')) {
      return 'http://$b';
    }
    return 'https://$b';
  }

  Uri _uri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${_normalizedBase()}$normalizedPath');
  }

  Map<String, String> _headers({String? bearerToken}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
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
        message: decoded['message']?.toString() ?? 'Request failed',
      );
    }
  }

  Future<Map<String, dynamic>> getJson(String path, {String? bearerToken}) async {
    final response = await _httpClient.get(_uri(path), headers: _headers(bearerToken: bearerToken));
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
    final response = await _httpClient.delete(_uri(path), headers: _headers(bearerToken: bearerToken));
    final decoded = _decode(response);
    _throwOnError(response, decoded);
  }
}

class ApiException implements Exception {
  ApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}
