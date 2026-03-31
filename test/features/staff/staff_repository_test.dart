import 'package:test/test.dart';
import 'package:funeralface_mobile/core/network/api_client.dart';
import 'package:funeralface_mobile/features/staff/staff_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('listStaff returns items', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/v1/staff');
      return http.Response('{"items":[{"id":"1","name":"A","phone":"1"}]}', 200);
    });

    final repo = StaffRepository(ApiClient(baseUrl: 'http://localhost:8010', httpClient: client));
    final items = await repo.listStaff();
    expect(items, hasLength(1));
    expect((items.first as Map<String, dynamic>)['name'], 'A');
  });

  test('createStaff posts payload', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/v1/staff');
      expect(request.body, '{"name":"Pat","phone":"555","role":"user"}');
      return http.Response('{"id":"new-1","name":"Pat","phone":"555","role":"user"}', 201);
    });

    final repo = StaffRepository(ApiClient(baseUrl: 'http://localhost:8010', httpClient: client));
    final row = await repo.createStaff(payload: {'name': 'Pat', 'phone': '555', 'role': 'user'});
    expect(row['id'], 'new-1');
  });

  test('updateStaff patches id', () async {
    final client = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(request.url.path, '/v1/staff/s1');
      expect(request.body, contains('"name":"Pat2"'));
      return http.Response('{"id":"s1","name":"Pat2","phone":"555","role":"user"}', 200);
    });

    final repo = StaffRepository(ApiClient(baseUrl: 'http://localhost:8010', httpClient: client));
    final row = await repo.updateStaff(id: 's1', payload: {'name': 'Pat2'});
    expect(row['name'], 'Pat2');
  });

  test('deleteStaff deletes id', () async {
    final client = MockClient((request) async {
      expect(request.method, 'DELETE');
      expect(request.url.path, '/v1/staff/s1');
      return http.Response('', 204);
    });

    final repo = StaffRepository(ApiClient(baseUrl: 'http://localhost:8010', httpClient: client));
    await repo.deleteStaff(id: 's1');
  });

  test('inviteByEmail posts invite', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/v1/staff/invite');
      expect(request.body, '{"email":"a@b.com"}');
      return http.Response(
        '{"status":"invited","email":"a@b.com","org_id":"org-1"}',
        202,
        headers: {'Content-Type': 'application/json'},
      );
    });

    final repo = StaffRepository(ApiClient(baseUrl: 'http://localhost:8010', httpClient: client));
    final r = await repo.inviteByEmail(email: 'a@b.com');
    expect(r['status'], 'invited');
  });
}
