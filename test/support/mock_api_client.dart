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

/// Mutable assignments API mock for widget interaction tests.
http.Client mockAssignmentsCrudHttpClient() {
  final items = <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'asgn-1',
      'decedent_name': 'John Doe',
      'pickup_address': '123 Main',
      'contact_name': 'Jane',
      'contact_phone': '555',
      'status': 'pending',
      'notes': '',
    },
  ];

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
    if (path == '/v1/assignments' && request.method == 'GET') {
      return http.Response(
        '{"items":${items.map((e) => _encodeJsonObject(e)).toList()}}',
        200,
        headers: {'Content-Type': 'application/json'},
      );
    }
    if (path == '/v1/assignments' && request.method == 'POST') {
      final body = request.body;
      final decedentName = _extractJsonValue(body, 'decedent_name') ?? 'Unknown';
      final pickupAddress = _extractJsonValue(body, 'pickup_address') ?? '';
      final contactName = _extractJsonValue(body, 'contact_name') ?? '';
      final contactPhone = _extractJsonValue(body, 'contact_phone') ?? '';
      final notes = _extractJsonValue(body, 'notes') ?? '';
      final nextId = 'asgn-${items.length + 1}';
      items.insert(0, <String, dynamic>{
        'id': nextId,
        'decedent_name': decedentName,
        'pickup_address': pickupAddress,
        'contact_name': contactName,
        'contact_phone': contactPhone,
        'status': 'pending',
        'notes': notes,
      });
      return http.Response('{"id":"$nextId","status":"pending"}', 201, headers: {'Content-Type': 'application/json'});
    }
    if (path.startsWith('/v1/assignments/') && request.method == 'PATCH') {
      final id = path.split('/').last;
      final nextStatus = _extractJsonValue(request.body, 'status');
      final idx = items.indexWhere((e) => e['id'] == id);
      if (idx >= 0 && nextStatus != null && nextStatus.isNotEmpty) {
        items[idx]['status'] = nextStatus;
      }
      return http.Response('{"id":"$id","status":"${nextStatus ?? ''}"}', 200, headers: {'Content-Type': 'application/json'});
    }

    return http.Response('{"code":"not_found","message":"unmocked"}', 404);
  });
}

String _encodeJsonObject(Map<String, dynamic> obj) {
  final pairs = obj.entries.map((e) => '"${e.key}":"${(e.value ?? '').toString().replaceAll('"', '\\"')}"').join(',');
  return '{$pairs}';
}

String? _extractJsonValue(String body, String key) {
  final marker = '"$key":"';
  final start = body.indexOf(marker);
  if (start < 0) return null;
  final from = start + marker.length;
  final end = body.indexOf('"', from);
  if (end < 0) return null;
  return body.substring(from, end);
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

/// Mutable staff API mock for widget interaction tests.
http.Client mockStaffCrudHttpClient() {
  final items = <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 's1',
      'name': 'Jane Staff',
      'phone': '555',
      'role': 'user',
      'email': 'jane@example.com',
    },
  ];

  return MockClient((request) async {
    final path = request.url.path;

    if (path.endsWith('/v1/settings')) {
      return http.Response(
        '{"funeral_home_name":"Mock Home","funeral_home_phone":"555","funeral_home_address":"1 Main St","default_message":null}',
        200,
        headers: {'Content-Type': 'application/json'},
      );
    }
    if (path.contains('/v1/assignments')) {
      return http.Response('{"items":[]}', 200, headers: {'Content-Type': 'application/json'});
    }
    if (path == '/v1/staff' && request.method == 'GET') {
      return http.Response(
        '{"items":${items.map((e) => _encodeJsonObject(e)).toList()}}',
        200,
        headers: {'Content-Type': 'application/json'},
      );
    }
    if (path == '/v1/staff' && request.method == 'POST') {
      final nextId = 's${items.length + 1}';
      final body = request.body;
      items.insert(0, <String, dynamic>{
        'id': nextId,
        'name': _extractJsonValue(body, 'name') ?? 'Unknown',
        'phone': _extractJsonValue(body, 'phone') ?? '',
        'role': _extractJsonValue(body, 'role') ?? 'user',
        'email': _extractJsonValue(body, 'email') ?? '',
      });
      return http.Response('{"id":"$nextId"}', 201, headers: {'Content-Type': 'application/json'});
    }
    if (path.startsWith('/v1/staff/') && request.method == 'PATCH') {
      final id = path.split('/').last;
      final idx = items.indexWhere((e) => e['id'] == id);
      if (idx >= 0) {
        final body = request.body;
        final name = _extractJsonValue(body, 'name');
        final phone = _extractJsonValue(body, 'phone');
        final role = _extractJsonValue(body, 'role');
        final email = _extractJsonValue(body, 'email');
        if (name != null) items[idx]['name'] = name;
        if (phone != null) items[idx]['phone'] = phone;
        if (role != null) items[idx]['role'] = role;
        if (email != null) items[idx]['email'] = email;
      }
      return http.Response('{"id":"$id"}', 200, headers: {'Content-Type': 'application/json'});
    }
    if (path.startsWith('/v1/staff/') && request.method == 'DELETE') {
      final id = path.split('/').last;
      items.removeWhere((e) => e['id'] == id);
      return http.Response('', 204);
    }
    if (path == '/v1/staff/invite' && request.method == 'POST') {
      final email = _extractJsonValue(request.body, 'email') ?? '';
      return http.Response('{"invited":"$email"}', 200, headers: {'Content-Type': 'application/json'});
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

http.Client mockDashboardHttpClient() {
  return MockClient((request) async {
    final path = request.url.path;
    if (path == '/v1/staff') {
      return http.Response(
        '{"items":[{"id":"s1"},{"id":"s2"}]}',
        200,
        headers: {'Content-Type': 'application/json'},
      );
    }
    if (path == '/v1/assignments') {
      return http.Response(
        '{"items":[{"id":"a1","decedent_name":"John Doe","pickup_address":"123 Main","status":"pending"},{"id":"a2","decedent_name":"Mary Roe","pickup_address":"42 Oak","status":"completed"}]}',
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
    return http.Response('{"code":"not_found","message":"unmocked"}', 404);
  });
}
