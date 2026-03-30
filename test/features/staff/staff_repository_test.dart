import 'package:test/test.dart';
import 'package:funeralface_mobile/core/network/api_client.dart';
import 'package:funeralface_mobile/features/staff/staff_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('inviteByEmail posts to staff invite', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/v1/staff/invite');
      expect(request.body, '{"email":"new@example.com"}');
      return http.Response(
        '{"status":"invited","email":"new@example.com","org_id":"org-1"}',
        202,
        headers: {'Content-Type': 'application/json'},
      );
    });

    final repo = StaffRepository(ApiClient(baseUrl: 'http://localhost:8010', httpClient: client));

    final result = await repo.inviteByEmail(email: 'new@example.com');
    expect(result['status'], 'invited');
    expect(result['email'], 'new@example.com');
  });

  test('listStaff returns items', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/v1/staff');
      return http.Response('{"items":[{"id":"1","name":"A"}]}', 200);
    });

    final repo = StaffRepository(ApiClient(baseUrl: 'http://localhost:8010', httpClient: client));
    final items = await repo.listStaff();
    expect(items, hasLength(1));
    expect((items.first as Map<String, dynamic>)['name'], 'A');
  });
}
