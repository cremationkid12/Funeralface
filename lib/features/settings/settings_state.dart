class SettingsState {
  const SettingsState({
    this.busy = false,
    this.saving = false,
    this.logoUploading = false,
    this.error,
    this.settings,
  });

  final bool busy;
  final bool saving;
  final bool logoUploading;
  final String? error;
  final Map<String, dynamic>? settings;

  SettingsState copyWith({
    bool? busy,
    bool? saving,
    bool? logoUploading,
    String? error,
    Map<String, dynamic>? settings,
    bool clearError = false,
  }) {
    return SettingsState(
      busy: busy ?? this.busy,
      saving: saving ?? this.saving,
      logoUploading: logoUploading ?? this.logoUploading,
      error: clearError ? null : (error ?? this.error),
      settings: settings ?? this.settings,
    );
  }
}
