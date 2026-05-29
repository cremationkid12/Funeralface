class StaffState {
  const StaffState({
    this.busy = false,
    this.submitting = false,
    this.items = const [],
    this.error,
    this.isAdmin = false,
  });

  final bool busy;
  final bool submitting;
  final List<dynamic> items;
  final String? error;

  /// Whether the signed-in user can invite or edit staff (admin only).
  final bool isAdmin;

  StaffState copyWith({
    bool? busy,
    bool? submitting,
    List<dynamic>? items,
    String? error,
    bool? isAdmin,
    bool clearError = false,
  }) {
    return StaffState(
      busy: busy ?? this.busy,
      submitting: submitting ?? this.submitting,
      items: items ?? this.items,
      error: clearError ? null : (error ?? this.error),
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
