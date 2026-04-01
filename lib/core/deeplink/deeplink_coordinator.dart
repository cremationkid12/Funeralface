import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:funeralface_mobile/core/deeplink/deeplink_parser.dart';
import 'package:go_router/go_router.dart';

/// Handles incoming app/universal links and routes family deep links in-app.
class DeeplinkCoordinator {
  DeeplinkCoordinator({
    required GoRouter router,
    required String expectedHost,
    AppLinks? appLinks,
  })  : _router = router,
        _expectedHost = expectedHost,
        _appLinks = appLinks ?? AppLinks();

  final GoRouter _router;
  final String _expectedHost;
  final AppLinks _appLinks;

  StreamSubscription<Uri>? _sub;
  String? _lastHandledUri;

  Future<void> start() async {
    final initial = await _appLinks.getInitialLink();
    _handleUri(initial);

    _sub = _appLinks.uriLinkStream.listen(_handleUri);
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  void _handleUri(Uri? uri) {
    if (uri == null) return;
    final raw = uri.toString();
    if (_lastHandledUri == raw) return;

    final token = extractFamilyAssignmentToken(
      uri,
      expectedHost: _expectedHost,
      allowQueryFallback: false,
    );
    if (token == null) return;

    _lastHandledUri = raw;
    _router.go('/family/${Uri.encodeComponent(token)}');
  }
}
