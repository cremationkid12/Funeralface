class AuthState {
  const AuthState({
    this.busy = false,
    this.error,
    this.info,
    this.success = false,
  });

  final bool busy;
  final String? error;
  final String? info;
  final bool success;

  AuthState copyWith({
    bool? busy,
    String? error,
    String? info,
    bool? success,
    bool clearError = false,
    bool clearInfo = false,
  }) {
    return AuthState(
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
      info: clearInfo ? null : (info ?? this.info),
      success: success ?? this.success,
    );
  }
}
