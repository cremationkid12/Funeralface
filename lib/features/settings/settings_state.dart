class SettingsState {
  const SettingsState({
    this.busy = false,
    this.saving = false,
    this.logoUploading = false,
    this.directorImageUploading = false,
    this.error,
    this.settings,
  });

  final bool busy;
  final bool saving;
  final bool logoUploading;
  final bool directorImageUploading;
  final String? error;
  final Map<String, dynamic>? settings;

  SettingsState copyWith({
    bool? busy,
    bool? saving,
    bool? logoUploading,
    bool? directorImageUploading,
    String? error,
    Map<String, dynamic>? settings,
    bool clearError = false,
  }) {
    return SettingsState(
      busy: busy ?? this.busy,
      saving: saving ?? this.saving,
      logoUploading: logoUploading ?? this.logoUploading,
      directorImageUploading:
          directorImageUploading ?? this.directorImageUploading,
      error: clearError ? null : (error ?? this.error),
      settings: settings ?? this.settings,
    );
  }
}
