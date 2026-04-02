import 'package:flutter/foundation.dart';

class AuthSession extends ChangeNotifier {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  String? _accessToken;
  String? _userId;

  String? get accessToken => _accessToken;
  String? get userId => _userId;
  bool get isAuthenticated => (_accessToken ?? '').trim().isNotEmpty;

  void setSession({
    required String? accessToken,
    required String? userId,
  }) {
    _accessToken = accessToken?.trim().isEmpty ?? true ? null : accessToken!.trim();
    _userId = userId;
    notifyListeners();
  }

  void clear() {
    _accessToken = null;
    _userId = null;
    notifyListeners();
  }
}
