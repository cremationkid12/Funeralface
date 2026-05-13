class DashboardOverview {
  DashboardOverview({
    required this.staffCount,
    required this.activeAssignments,
    required this.completedAssignments,
    required this.recentAssignments,
  });

  final int staffCount;
  final int activeAssignments;
  final int completedAssignments;
  final List<Map<String, dynamic>> recentAssignments;

  static const int maxRecentAssignments = 5;
}

class DashboardState {
  const DashboardState({this.busy = false, this.overview, this.error});

  final bool busy;
  final DashboardOverview? overview;
  final String? error;

  DashboardState copyWith({
    bool? busy,
    DashboardOverview? overview,
    String? error,
    bool clearError = false,
  }) {
    return DashboardState(
      busy: busy ?? this.busy,
      overview: overview ?? this.overview,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
