import 'dart:io';

import 'package:everroute/core/navigation/notification_navigation.dart';
import 'package:everroute/core/network/api_client.dart';
import 'package:everroute/features/session/staff_auth.dart';
import 'package:everroute/models/notification_model.dart';
import 'package:everroute/services/push_services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

typedef PushRefreshListener = void Function();

class PushNotificationCoordinator {
  PushNotificationCoordinator._();

  static final PushNotificationCoordinator instance =
      PushNotificationCoordinator._();

  PushServices? _pushServices;
  GoRouter? _router;
  String? _lastRegisteredToken;
  final List<PushRefreshListener> _refreshListeners = [];

  bool get isEnabled => _pushServices != null;

  void addRefreshListener(PushRefreshListener listener) {
    _refreshListeners.add(listener);
  }

  void removeRefreshListener(PushRefreshListener listener) {
    _refreshListeners.remove(listener);
  }

  void _notifyRefreshListeners() {
    for (final listener in List<PushRefreshListener>.from(_refreshListeners)) {
      listener();
    }
  }

  Future<bool> initialize({
    required GoRouter router,
    required ApiClient apiClient,
  }) async {
    _router = router;
    _pushServices = PushServices(apiClient);

    try {
      await Firebase.initializeApp();
    } catch (error) {
      debugPrint('Push disabled: Firebase not configured ($error)');
      _pushServices = null;
      return false;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final permission = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (permission.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Push permission denied by user.');
    }

    FirebaseMessaging.onMessage.listen((message) {
      _notifyRefreshListeners();
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleOpenedMessage(initialMessage);
    }

    messaging.onTokenRefresh.listen((token) {
      _registerToken(token);
    });

    return true;
  }

  Future<void> registerIfAuthenticated() async {
    if (_pushServices == null) return;
    final bearerToken = staffBearerToken();
    if (bearerToken == null) return;

    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _registerToken(token, bearerToken: bearerToken);
    } catch (error) {
      debugPrint('Push token registration failed: $error');
    }
  }

  Future<void> unregisterCurrentDevice() async {
    if (_pushServices == null) return;
    final bearerToken = staffBearerToken();
    if (bearerToken == null) return;

    try {
      final token = _lastRegisteredToken ?? await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _pushServices!.unregister(
          bearerToken: bearerToken,
          fcmToken: token,
        );
      }
      _lastRegisteredToken = null;
    } catch (error) {
      debugPrint('Push token unregister failed: $error');
    }
  }

  Future<void> _registerToken(
    String token, {
    String? bearerToken,
  }) async {
    if (_pushServices == null) return;
    final authToken = bearerToken ?? staffBearerToken();
    if (authToken == null) return;

    final platform = Platform.isIOS ? 'ios' : 'android';
    await _pushServices!.register(
      bearerToken: authToken,
      fcmToken: token,
      platform: platform,
    );
    _lastRegisteredToken = token;
  }

  void _handleOpenedMessage(RemoteMessage message) {
    final router = _router;
    if (router == null) return;
    final notification = NotificationModel.fromPushData(message.data);
    if (notification == null) return;
    navigateForNotification(router, notification);
  }
}
