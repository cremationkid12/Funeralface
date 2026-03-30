import 'package:test/test.dart';
import 'package:funeralface_mobile/core/network/api_client.dart';
import 'package:funeralface_mobile/features/family/family_assignment_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('getByToken returns view on 200', () async {
    final client = MockClient((request) async {
      expect(request.url.path, contains('/v1/public/assignments/by-token/'));
      return http.Response(
        '{"assignment_id":"a1","decedent_name":"X","status":"pending","eta_note":null,"support_contact_phone":"555"}',
        200,
      );
    });

    final repo = FamilyAssignmentRepository(
      ApiClient(baseUrl: 'http://localhost:8010', httpClient: client),
    );

    final result = await repo.getByToken('my-token');
    expect(result.isOk, isTrue);
    expect(result.view?.assignmentId, 'a1');
    expect(result.view?.supportContactPhone, '555');
  });

  test('getByToken maps 404 to notFound', () async {
    final client = MockClient(
      (_) async => http.Response('{"code":"not_found","message":"nope"}', 404),
    );

    final repo = FamilyAssignmentRepository(
      ApiClient(baseUrl: 'http://localhost:8010', httpClient: client),
    );

    final result = await repo.getByToken('t');
    expect(result.isOk, isFalse);
    expect(result.failureCode, FamilyAssignmentFailure.notFound);
  });

  test('getByToken maps 410 to expired', () async {
    final client = MockClient(
      (_) async => http.Response('{"code":"token_expired","message":"exp"}', 410),
    );

    final repo = FamilyAssignmentRepository(
      ApiClient(baseUrl: 'http://localhost:8010', httpClient: client),
    );

    final result = await repo.getByToken('t');
    expect(result.failureCode, FamilyAssignmentFailure.expired);
  });

  test('getByToken maps 429 to rateLimited', () async {
    final client = MockClient(
      (_) async => http.Response('{"code":"rate_limited","message":"slow"}', 429),
    );

    final repo = FamilyAssignmentRepository(
      ApiClient(baseUrl: 'http://localhost:8010', httpClient: client),
    );

    final result = await repo.getByToken('t');
    expect(result.failureCode, FamilyAssignmentFailure.rateLimited);
  });
}
