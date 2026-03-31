import 'package:funeralface_mobile/core/network/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Minimal happy-path responses for shell / tab smoke tests.
http.Client mockStaffAppHttpClient() {
  return MockClient((request) async {
    final path = request.url.path;
    if (path.endsWith('/v1/settings')) {
      return http.Response(
        '{"funeral_home_name":"Mock Home","funeral_home_phone":"555","funeral_home_address":"1 Main St","default_message":null}',
        200,
        headers: {'Content-Type': 'application/json'},
      );
    }
    if (path == '/v1/staff') {
      return http.Response(
        '{"items":[]}',
        200,
        headers: {'Content-Type': 'application/json'},
      );
    }
    if (path.contains('/v1/assignments')) {
      return http.Response(
        '{"items":[]}',
        200,
        headers: {'Content-Type': 'application/json'},
      );
    }
    return http.Response('{"code":"not_found","message":"unmocked"}', 404);
  });
}

http.Client mockStaffAppHttpClientWithAssignmentList() {
  return MockClient((request) async {
    final path = request.url.path;
    if (path.endsWith('/v1/settings')) {
      return http.Response(
        '{"funeral_home_name":"Mock Home","funeral_home_phone":"555","funeral_home_address":"1 Main St","default_message":null}',
        200,
        headers: {'Content-Type': 'application/json'},
      );
    }
    if (path == '/v1/staff') {
      return http.Response('{"items":[]}', 200, headers: {'Content-Type': 'application/json'});
    }
    if (path == '/v1/assignments') {
      return http.Response(
        r'{"items":[{"id":"asgn-1","decedent_name":"John Doe","pickup_address":"123 Main","contact_name":"Jane","contact_phone":"555" ,"status":"pending","notes":""}]}',
        200,
        headers: {'Content-Type': 'application/json'},
      );
    }
    if (path == '/v1/assignments/asgn-1') {
      return http.Response('{"id":"asgn-1","status":"pending"}', 200, headers: {'Content-Type': 'application/json'});
    }
    return http.Response('{"code":"not_found","message":"unmocked"}', 404);
  });
}

http.Client mockStaffAppHttpClientWithStaffList() {
  return MockClient((request) async {
    final path = request.url.path;
    if (path.endsWith('/v1/settings')) {
      return http.Response(
        '{"funeral_home_name":"Mock Home","funeral_home_phone":"555","funeral_home_address":"1 Main St","default_message":null}',
        200,
        headers: {'Content-Type': 'application/json'},
      );
    }
    if (path == '/v1/staff') {
      return http.Response(
        '{"items":[{"id":"s1","name":"Jane Staff","phone":"555","role":"user"}]}',
        200,
        headers: {'Content-Type': 'application/json'},
      );
    }
    if (path.contains('/v1/assignments')) {
      return http.Response('{"items":[]}', 200, headers: {'Content-Type': 'application/json'});
    }
    return http.Response('{"code":"not_found","message":"unmocked"}', 404);
  });
}

/// Public family token GET for deep-link widget tests.
http.Client mockFamilyTokenHttpClient() {
  return MockClient((request) async {
    final path = request.url.path;
    if (path == '/v1/public/assignments/by-token/tok-1') {
      return http.Response(
        '{"assignment_id":"a1","decedent_name":"Jane Doe","status":"en_route","eta_note":null,"support_contact_phone":"555-0100"}',
        200,
        headers: {'Content-Type': 'application/json'},
      );
    }
    if (path.endsWith('/v1/settings')) {
      return http.Response(
        '{"funeral_home_name":"Mock Home","funeral_home_phone":"555","funeral_home_address":"1 Main St","default_message":null}',
        200,
        headers: {'Content-Type': 'application/json'},
      );
    }
    if (path == '/v1/staff') {
      return http.Response('{"items":[]}', 200, headers: {'Content-Type': 'application/json'});
    }
    if (path.contains('/v1/assignments')) {
      return http.Response('{"items":[]}', 200, headers: {'Content-Type': 'application/json'});
    }
    return http.Response('{"code":"not_found","message":"unmocked"}', 404);
  });
}

ApiClient mockStaffAppApiClient() {
  return ApiClient(
    baseUrl: 'http://localhost:8010',
    httpClient: mockStaffAppHttpClient(),
  );
}
