import 'package:flutter_test/flutter_test.dart';
import 'package:funeralface_mobile/core/network/api_client.dart';
import 'package:funeralface_mobile/features/assignments/assignments_repository.dart';
import 'package:funeralface_mobile/features/dashboard/dashboard_usecase.dart';
import 'package:funeralface_mobile/features/staff/staff_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('DashboardUseCase aggregates staff and assignment counts', () async {
    final client = MockClient((request) async {
      final path = request.url.path;
      if (path == '/v1/staff') {
        return http.Response('{"items":[{"id":"1"},{"id":"2"}]}', 200);
      }
      if (path == '/v1/assignments') {
        return http.Response(
          '{"items":[{"id":"a1","status":"pending"},{"id":"a2","status":"completed"}]}',
          200,
        );
      }
      return http.Response('{"message":"not found"}', 404);
    });

    final apiClient = ApiClient(baseUrl: 'http://localhost:3000', httpClient: client);
    final useCase = DashboardUseCase(
      staffRepository: StaffRepository(apiClient),
      assignmentsRepository: AssignmentsRepository(apiClient),
    );

    final result = await useCase.loadSummary();
    expect(result.staffCount, 2);
    expect(result.activeAssignments, 1);
    expect(result.completedAssignments, 1);
  });
}
