import '../assignments/assignments_repository.dart';
import '../staff/staff_repository.dart';

class DashboardSummary {
  DashboardSummary({
    required this.staffCount,
    required this.activeAssignments,
    required this.completedAssignments,
  });

  final int staffCount;
  final int activeAssignments;
  final int completedAssignments;
}

class DashboardUseCase {
  DashboardUseCase({
    required StaffRepository staffRepository,
    required AssignmentsRepository assignmentsRepository,
  })  : _staffRepository = staffRepository,
        _assignmentsRepository = assignmentsRepository;

  final StaffRepository _staffRepository;
  final AssignmentsRepository _assignmentsRepository;

  Future<DashboardSummary> loadSummary({String? bearerToken}) async {
    final results = await Future.wait([
      _staffRepository.listStaff(bearerToken: bearerToken),
      _assignmentsRepository.listAssignments(bearerToken: bearerToken),
    ]);

    final staff = results[0];
    final assignments = results[1];
    final completed = assignments.where((a) => a['status'] == 'completed').length;
    final active = assignments.length - completed;

    return DashboardSummary(
      staffCount: staff.length,
      activeAssignments: active,
      completedAssignments: completed,
    );
  }
}
