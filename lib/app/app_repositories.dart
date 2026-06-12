import 'package:everroute/core/network/api_client.dart';
import 'package:everroute/services/assignments_services.dart';
import 'package:everroute/services/billing_services.dart';
import 'package:everroute/services/settings_services.dart';
import 'package:everroute/services/notifications_services.dart';
import 'package:everroute/services/staff_services.dart';

/// Shared repositories and use cases for the staff app shell.
class AppRepositories {
  AppRepositories({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  late final SettingsServices settings = SettingsServices(_api);
  late final StaffServices staff = StaffServices(_api);
  late final AssignmentsServices assignments = AssignmentsServices(_api);
  late final BillingServices billing = BillingServices(_api);
  late final NotificationsServices notifications = NotificationsServices(_api);
}
