import '../../services/assignments_services.dart';
import '../../services/staff_services.dart';

/// Dashboard counts plus a short recent-assignments list (API returns newest first).
class DashboardOverview {
  DashboardOverview({
    required this.staffCount,
    required this.activeAssignments,
    required this.completedAssignments,
    required this.recentAssignments,
  });

  final int staffCount;
  final int activeAssignments;
  final int completedAssignments;

  /// Up to [maxRecentAssignments] items, maps as returned by `/v1/assignments`.
  final List<Map<String, dynamic>> recentAssignments;

  static const int maxRecentAssignments = 5;
}

class DashboardUseCase {
  DashboardUseCase({
    required StaffServices staffRepository,
    required AssignmentsServices assignmentsRepository,
  }) : _staffRepository = staffRepository,
       _assignmentsRepository = assignmentsRepository;

  final StaffServices _staffRepository;
  final AssignmentsServices _assignmentsRepository;

  Future<DashboardOverview> loadOverview({String? bearerToken}) async {
    final results = await Future.wait<List<dynamic>>([
      _staffRepository.listStaff(bearerToken: bearerToken),
      _assignmentsRepository.listAssignments(bearerToken: bearerToken),
    ]);

    final staff = results[0];
    final assignments = results[1];
    final completed = assignments
        .where((a) => (a as Map)['status'] == 'completed')
        .length;
    final active = assignments.length - completed;

    final recent = assignments
        .take(DashboardOverview.maxRecentAssignments)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return DashboardOverview(
      staffCount: staff.length,
      activeAssignments: active,
      completedAssignments: completed,
      recentAssignments: recent,
    );
  }
}
