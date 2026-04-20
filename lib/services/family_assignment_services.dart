import '../core/network/api_client.dart';
import '../features/family/family_assignment_view.dart';

enum FamilyAssignmentFailure { notFound, expired, rateLimited, unknown }

class FamilyAssignmentResult {
  const FamilyAssignmentResult._(this.view, this.failureCode, this.message);

  final FamilyAssignmentView? view;
  final FamilyAssignmentFailure? failureCode;
  final String? message;

  factory FamilyAssignmentResult.ok(FamilyAssignmentView view) {
    return FamilyAssignmentResult._(view, null, null);
  }

  factory FamilyAssignmentResult.failure(
    FamilyAssignmentFailure code, {
    String? message,
  }) {
    return FamilyAssignmentResult._(null, code, message);
  }

  bool get isOk => view != null;
}

/// Reads family-assignment data via the public token endpoint (no auth).
class FamilyAssignmentServices {
  FamilyAssignmentServices(this._apiClient);

  final ApiClient _apiClient;

  /// GET `/v1/public/assignments/by-token/{token}` — [token] must be URL-safe when embedded in path.
  Future<FamilyAssignmentResult> getByToken(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      return FamilyAssignmentResult.failure(FamilyAssignmentFailure.notFound);
    }

    final encoded = Uri.encodeComponent(trimmed);
    final path = '/v1/public/assignments/by-token/$encoded';

    try {
      final json = await _apiClient.getJson(path);
      return FamilyAssignmentResult.ok(FamilyAssignmentView.fromJson(json));
    } on ApiException catch (e) {
      switch (e.statusCode) {
        case 404:
          return FamilyAssignmentResult.failure(
            FamilyAssignmentFailure.notFound,
            message: e.message,
          );
        case 410:
          return FamilyAssignmentResult.failure(
            FamilyAssignmentFailure.expired,
            message: e.message,
          );
        case 429:
          return FamilyAssignmentResult.failure(
            FamilyAssignmentFailure.rateLimited,
            message: e.message,
          );
        default:
          return FamilyAssignmentResult.failure(
            FamilyAssignmentFailure.unknown,
            message: e.message,
          );
      }
    }
  }
}
