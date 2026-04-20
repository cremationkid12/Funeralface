class AssignmentsState {
  const AssignmentsState({
    this.busy = false,
    this.submitting = false,
    this.items = const [],
    this.filteredItems = const [],
    this.searchQuery = '',
    this.expandedIds = const <String>{},
    this.error,
  });

  final bool busy;
  final bool submitting;
  final List<dynamic> items;
  final List<dynamic> filteredItems;
  final String searchQuery;
  final Set<String> expandedIds;
  final String? error;

  AssignmentsState copyWith({
    bool? busy,
    bool? submitting,
    List<dynamic>? items,
    List<dynamic>? filteredItems,
    String? searchQuery,
    Set<String>? expandedIds,
    String? error,
    bool clearError = false,
  }) {
    return AssignmentsState(
      busy: busy ?? this.busy,
      submitting: submitting ?? this.submitting,
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      searchQuery: searchQuery ?? this.searchQuery,
      expandedIds: expandedIds ?? this.expandedIds,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
