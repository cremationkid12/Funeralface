class StaffState {
  const StaffState({
    this.busy = false,
    this.submitting = false,
    this.items = const [],
    this.error,
  });

  final bool busy;
  final bool submitting;
  final List<dynamic> items;
  final String? error;

  StaffState copyWith({
    bool? busy,
    bool? submitting,
    List<dynamic>? items,
    String? error,
    bool clearError = false,
  }) {
    return StaffState(
      busy: busy ?? this.busy,
      submitting: submitting ?? this.submitting,
      items: items ?? this.items,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
