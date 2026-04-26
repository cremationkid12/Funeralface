import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:funeralface_mobile/features/settings/settings_state.dart';
import 'package:funeralface_mobile/services/settings_services.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({required SettingsServices settingsServices})
    : _settingsServices = settingsServices,
      super(const SettingsState());

  final SettingsServices _settingsServices;

  Future<void> load({required String bearerToken}) async {
    emit(state.copyWith(busy: true, clearError: true));
    try {
      final data = await _settingsServices.getSettings(
        bearerToken: bearerToken,
      );
      emit(
        state.copyWith(
          busy: false,
          error: null,
          settings: Map<String, dynamic>.from(data),
        ),
      );
    } catch (error) {
      emit(state.copyWith(busy: false, error: error.toString()));
    }
  }

  Future<Map<String, dynamic>> save({
    required String bearerToken,
    required Map<String, dynamic> payload,
  }) async {
    emit(state.copyWith(saving: true, clearError: true));
    try {
      final updated = await _settingsServices.updateSettings(
        payload,
        bearerToken: bearerToken,
      );
      final normalized = Map<String, dynamic>.from(updated);
      emit(state.copyWith(saving: false, error: null, settings: normalized));
      return normalized;
    } catch (error) {
      emit(state.copyWith(saving: false, error: error.toString()));
      rethrow;
    }
  }

  Future<String> uploadLogo({
    required String bearerToken,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    emit(state.copyWith(logoUploading: true, clearError: true));
    try {
      final logoUrl = await _settingsServices.uploadImageAsset(
        bearerToken: bearerToken,
        bytes: fileBytes,
        fileName: fileName,
        purpose: 'funeral_home_logo',
      );
      final nextSettings = Map<String, dynamic>.from(
        state.settings ?? const {},
      );
      nextSettings['logo_url'] = logoUrl;
      emit(
        state.copyWith(
          logoUploading: false,
          error: null,
          settings: nextSettings,
        ),
      );
      return logoUrl;
    } catch (error) {
      emit(state.copyWith(logoUploading: false, error: error.toString()));
      rethrow;
    }
  }

  void clear() {
    emit(const SettingsState());
  }
}
