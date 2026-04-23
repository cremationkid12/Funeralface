import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:funeralface_mobile/features/staff/staff_state.dart';
import 'package:funeralface_mobile/services/staff_services.dart';

class StaffCubit extends Cubit<StaffState> {
  StaffCubit({required StaffServices staffServices})
    : _staffServices = staffServices,
      super(const StaffState());

  final StaffServices _staffServices;

  Future<void> load({required String bearerToken}) async {
    emit(state.copyWith(busy: true, clearError: true));
    try {
      final items = await _staffServices.listStaff(bearerToken: bearerToken);
      emit(state.copyWith(busy: false, items: items, error: null));
    } catch (error) {
      emit(state.copyWith(busy: false, error: error.toString()));
    }
  }

  void clear() {
    emit(const StaffState(busy: false, items: []));
  }

  Future<void> refresh({required String bearerToken}) async {
    await load(bearerToken: bearerToken);
  }

  Future<Map<String, dynamic>> createStaff({
    required Map<String, dynamic> payload,
    required String bearerToken,
  }) async {
    emit(state.copyWith(submitting: true, clearError: true));
    try {
      final created = await _staffServices.createStaff(
        payload: payload,
        bearerToken: bearerToken,
      );
      final next = [created, ...state.items];
      emit(state.copyWith(submitting: false, items: next, error: null));
      return created;
    } catch (error) {
      emit(state.copyWith(submitting: false, error: error.toString()));
      rethrow;
    }
  }

  Future<void> inviteByEmail({
    required String email,
    required String bearerToken,
  }) async {
    emit(state.copyWith(submitting: true, clearError: true));
    try {
      await _staffServices.inviteByEmail(
        email: email,
        bearerToken: bearerToken,
      );
      emit(state.copyWith(submitting: false, error: null));
    } catch (error) {
      emit(state.copyWith(submitting: false, error: error.toString()));
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateStaff({
    required String id,
    required Map<String, dynamic> payload,
    required String bearerToken,
  }) async {
    emit(state.copyWith(submitting: true, clearError: true));
    try {
      final updated = await _staffServices.updateStaff(
        id: id,
        payload: payload,
        bearerToken: bearerToken,
      );
      emit(
        state.copyWith(
          submitting: false,
          items: _upsertStaff(state.items, updated),
          error: null,
        ),
      );
      return updated;
    } catch (error) {
      emit(state.copyWith(submitting: false, error: error.toString()));
      rethrow;
    }
  }

  Future<Map<String, dynamic>> activateStaff({
    required String id,
    required String bearerToken,
  }) async {
    emit(state.copyWith(submitting: true, clearError: true));
    try {
      final updated = await _staffServices.activateStaff(
        id: id,
        bearerToken: bearerToken,
      );
      emit(
        state.copyWith(
          submitting: false,
          items: _upsertStaff(state.items, updated),
          error: null,
        ),
      );
      return updated;
    } catch (error) {
      emit(state.copyWith(submitting: false, error: error.toString()));
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deactivateStaff({
    required String id,
    required String bearerToken,
  }) async {
    emit(state.copyWith(submitting: true, clearError: true));
    try {
      final updated = await _staffServices.deactivateStaff(
        id: id,
        bearerToken: bearerToken,
      );
      emit(
        state.copyWith(
          submitting: false,
          items: _upsertStaff(state.items, updated),
          error: null,
        ),
      );
      return updated;
    } catch (error) {
      emit(state.copyWith(submitting: false, error: error.toString()));
      rethrow;
    }
  }

  Future<void> deleteStaff({
    required String id,
    required String bearerToken,
  }) async {
    emit(state.copyWith(submitting: true, clearError: true));
    try {
      await _staffServices.deleteStaff(id: id, bearerToken: bearerToken);
      final next = state.items
          .where((it) => (it as Map<String, dynamic>)['id']?.toString() != id)
          .toList();
      emit(state.copyWith(submitting: false, items: next, error: null));
    } catch (error) {
      emit(state.copyWith(submitting: false, error: error.toString()));
      rethrow;
    }
  }

  void upsertFromDetail(Map<String, dynamic> item) {
    emit(state.copyWith(items: _upsertStaff(state.items, item)));
  }

  List<dynamic> _upsertStaff(
    List<dynamic> current,
    Map<String, dynamic> updated,
  ) {
    final updatedId = updated['id']?.toString();
    if (updatedId == null || updatedId.isEmpty) return current;
    var found = false;
    final next = current.map((it) {
      final map = it as Map<String, dynamic>;
      if (map['id']?.toString() == updatedId) {
        found = true;
        return updated;
      }
      return it;
    }).toList();
    if (!found) next.insert(0, updated);
    return next;
  }
}
