import 'package:funeralface_mobile/core/network/api_client.dart';
import 'package:funeralface_mobile/services/assignments_services.dart';
import 'package:funeralface_mobile/services/family_assignment_services.dart';
import 'package:funeralface_mobile/services/settings_services.dart';
import 'package:funeralface_mobile/services/staff_services.dart';

/// Shared repositories and use cases for the staff app shell.
class AppRepositories {
  AppRepositories({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  late final SettingsServices settings = SettingsServices(_api);
  late final StaffServices staff = StaffServices(_api);
  late final AssignmentsServices assignments = AssignmentsServices(_api);

  /// Public family token flow (no bearer auth).
  late final FamilyAssignmentServices familyAssignments =
      FamilyAssignmentServices(_api);
}
