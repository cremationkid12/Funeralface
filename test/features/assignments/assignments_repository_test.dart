import 'package:test/test.dart';
import 'package:funeralface_mobile/core/network/api_client.dart';
import 'package:funeralface_mobile/features/assignments/assignments_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('listAssignments requests sorted list endpoint', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/v1/assignments');
      expect(request.url.queryParameters['sort'], '-created_at');
      return http.Response('{"items":[{"id":"a1"}]}', 200);
    });

    final repo = AssignmentsRepository(
      ApiClient(baseUrl: 'http://localhost:8010', httpClient: client),
    );

    final items = await repo.listAssignments();
    expect(items, hasLength(1));
    expect((items.first as Map<String, dynamic>)['id'], 'a1');
  });

  test('createAssignment posts expected payload', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/v1/assignments');
      expect(request.body, contains('"decedent_name":"Jane Doe"'));
      expect(request.body, contains('"contact_phone":"555-0001"'));
      return http.Response('{"id":"new-1","status":"pending"}', 201);
    });

    final repo = AssignmentsRepository(
      ApiClient(baseUrl: 'http://localhost:8010', httpClient: client),
    );

    final created = await repo.createAssignment(
      payload: {
        'decedent_name': 'Jane Doe',
        'pickup_address': '123 Main St',
        'contact_name': 'John Doe',
        'contact_phone': '555-0001',
      },
    );

    expect(created['id'], 'new-1');
    expect(created['status'], 'pending');
  });

  test('updateAssignment patches target assignment with status', () async {
    final client = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(request.url.path, '/v1/assignments/asg-1');
      expect(request.body, '{"status":"arrived"}');
      return http.Response('{"id":"asg-1","status":"arrived"}', 200);
    });

    final repo = AssignmentsRepository(
      ApiClient(baseUrl: 'http://localhost:8010', httpClient: client),
    );

    final updated = await repo.updateAssignment(
      assignmentId: 'asg-1',
      payload: {'status': 'arrived'},
    );

    expect(updated['id'], 'asg-1');
    expect(updated['status'], 'arrived');
  });
}
