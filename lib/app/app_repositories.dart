import 'package:funeralface_mobile/core/network/api_client.dart';
import 'package:funeralface_mobile/features/assignments/assignments_repository.dart';
import 'package:funeralface_mobile/features/dashboard/dashboard_usecase.dart';
import 'package:funeralface_mobile/features/settings/settings_repository.dart';
import 'package:funeralface_mobile/features/staff/staff_repository.dart';

/// Shared repositories and use cases for the staff app shell.
class AppRepositories {
  AppRepositories({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  late final SettingsRepository settings = SettingsRepository(_api);
  late final StaffRepository staff = StaffRepository(_api);
  late final AssignmentsRepository assignments = AssignmentsRepository(_api);

  late final DashboardUseCase dashboard = DashboardUseCase(
    staffRepository: staff,
    assignmentsRepository: assignments,
  );
}
