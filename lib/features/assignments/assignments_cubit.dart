import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:funeralface_mobile/features/assignments/assignments_state.dart';
import 'package:funeralface_mobile/services/assignments_services.dart';

class AssignmentsCubit extends Cubit<AssignmentsState> {
  AssignmentsCubit({required AssignmentsServices assignmentsServices})
    : _assignmentsServices = assignmentsServices,
      super(const AssignmentsState());

  final AssignmentsServices _assignmentsServices;

  Future<void> load({required String bearerToken}) async {
    emit(state.copyWith(busy: true, error: null));
    await _fetchAssignments(bearerToken: bearerToken);
  }

  Future<void> refresh({required String bearerToken}) async {
    await _fetchAssignments(bearerToken: bearerToken, keepBusy: true);
  }

  void setSearchQuery(String query) {
    emit(
      state.copyWith(
        searchQuery: query,
        filteredItems: _filter(state.items, query),
      ),
    );
  }

  void toggleExpanded(String assignmentId) {
    final next = Set<String>.from(state.expandedIds);
    if (next.contains(assignmentId)) {
      next.remove(assignmentId);
    } else {
      next.add(assignmentId);
    }
    emit(state.copyWith(expandedIds: next));
  }

  Future<void> updateStatus({
    required String assignmentId,
    required String status,
    required String bearerToken,
  }) async {
    emit(state.copyWith(submitting: true, error: null));
    try {
      await _assignmentsServices.updateAssignment(
        assignmentId: assignmentId,
        payload: {'status': status},
        bearerToken: bearerToken,
      );
      await _fetchAssignments(bearerToken: bearerToken, keepBusy: true);
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
      rethrow;
    } finally {
      emit(state.copyWith(submitting: false));
    }
  }

  Future<void> createAssignment({
    required Map<String, dynamic> payload,
    required String bearerToken,
  }) async {
    emit(state.copyWith(submitting: true, error: null));
    try {
      await _assignmentsServices.createAssignment(
        payload: payload,
        bearerToken: bearerToken,
      );
      await _fetchAssignments(bearerToken: bearerToken, keepBusy: true);
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
      rethrow;
    } finally {
      emit(state.copyWith(submitting: false));
    }
  }

  Future<Map<String, dynamic>> updateAssignment({
    required String assignmentId,
    required Map<String, dynamic> payload,
    required String bearerToken,
  }) async {
    emit(state.copyWith(submitting: true, error: null));
    try {
      final updated = await _assignmentsServices.updateAssignment(
        assignmentId: assignmentId,
        payload: payload,
        bearerToken: bearerToken,
      );
      print('updated: $updated');
      final nextItems = _upsertAssignment(state.items, updated);
      emit(
        state.copyWith(
          submitting: false,
          items: nextItems,
          filteredItems: _filter(nextItems, state.searchQuery),
        ),
      );
      return updated;
    } catch (error) {
      print('error: $error');
      emit(state.copyWith(submitting: false, error: error.toString()));
      rethrow;
    }
  }

  Future<void> _fetchAssignments({
    required String bearerToken,
    bool keepBusy = false,
  }) async {
    try {
      final items = await _assignmentsServices.listAssignments(
        bearerToken: bearerToken,
      );
      final filtered = _filter(items, state.searchQuery);
      final validIds = items
          .map((m) => (m as Map<String, dynamic>)['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      final expanded = state.expandedIds.where(validIds.contains).toSet();
      emit(
        state.copyWith(
          busy: false,
          items: items,
          filteredItems: filtered,
          expandedIds: expanded,
          error: null,
        ),
      );
    } catch (error) {
      emit(state.copyWith(busy: false, error: error.toString()));
    } finally {
      if (keepBusy && state.busy) {
        emit(state.copyWith(busy: false));
      }
    }
  }

  List<dynamic> _filter(List<dynamic> items, String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return List<dynamic>.of(items);
    return items.where((m) {
      final map = m as Map<String, dynamic>;
      final name = (map['decedent_name'] ?? '').toString().toLowerCase();
      final addr = (map['pickup_address'] ?? '').toString().toLowerCase();
      final status = (map['status'] ?? '').toString().toLowerCase();
      return name.contains(q) || addr.contains(q) || status.contains(q);
    }).toList();
  }

  List<dynamic> _upsertAssignment(
    List<dynamic> current,
    Map<String, dynamic> updated,
  ) {
    final updatedId = updated['id']?.toString();
    if (updatedId == null || updatedId.isEmpty) return current;
    var found = false;
    final next = current.map((item) {
      final map = item as Map<String, dynamic>;
      if (map['id']?.toString() == updatedId) {
        found = true;
        return updated;
      }
      return item;
    }).toList();
    if (!found) next.insert(0, updated);
    return next;
  }
}
