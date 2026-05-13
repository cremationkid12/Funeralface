import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:everroute/core/env.dart';
import 'package:everroute/core/network/api_client.dart';
import 'package:everroute/services/assignments_services.dart';
import 'package:everroute/features/dashboard/dashboard_state.dart';
import 'package:everroute/services/auth_services.dart';
import 'package:everroute/services/staff_services.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({
    required StaffServices staffServices,
    required AssignmentsServices assignmentsServices,
    required ApiClient apiClient,
  }) : _staffServices = staffServices,
       _assignmentsServices = assignmentsServices,
       _apiClient = apiClient,
       super(const DashboardState());

  final StaffServices _staffServices;
  final AssignmentsServices _assignmentsServices;
  final ApiClient _apiClient;

  Future<void> load({required String bearerToken}) async {
    emit(state.copyWith(busy: true, clearError: true));
    try {
      if (AppEnv.hasSupabaseAuthConfig) {
        try {
          await ensureBackendProvisioned(_apiClient, bearerToken);
        } catch (_) {}
      }

      final results = await Future.wait<List<dynamic>>([
        _staffServices.listStaff(bearerToken: bearerToken),
        _assignmentsServices.listAssignments(bearerToken: bearerToken),
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

      final overview = DashboardOverview(
        staffCount: staff.length,
        activeAssignments: active,
        completedAssignments: completed,
        recentAssignments: recent,
      );
      emit(state.copyWith(busy: false, overview: overview, error: null));
    } catch (error) {
      emit(state.copyWith(busy: false, error: error.toString()));
    }
  }

  Future<void> refresh({required String bearerToken}) async {
    await load(bearerToken: bearerToken);
  }

  void clear() {
    emit(const DashboardState());
  }
}
