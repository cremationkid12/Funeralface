import 'package:flutter/foundation.dart';

/// Notifies [DashboardScreen] to reload overview data from the API.
///
/// Used when assignments are created or otherwise changed elsewhere while
/// the dashboard tab stays mounted (e.g. [IndexedStack] in the main shell).
class DashboardOverviewInvalidation extends ChangeNotifier {
  DashboardOverviewInvalidation._();

  static final DashboardOverviewInvalidation instance =
      DashboardOverviewInvalidation._();

  void invalidate() => notifyListeners();
}
