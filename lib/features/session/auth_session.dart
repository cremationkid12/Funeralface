import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthSessionState {
  const AuthSessionState({this.accessToken, this.userId});

  final String? accessToken;
  final String? userId;

  bool get isAuthenticated => (accessToken ?? '').trim().isNotEmpty;
}

class AuthSession extends Cubit<AuthSessionState> implements Listenable {
  AuthSession._() : super(const AuthSessionState());

  static final AuthSession instance = AuthSession._();

  final Set<VoidCallback> _listeners = <VoidCallback>{};

  String? get accessToken => state.accessToken;
  String? get userId => state.userId;
  bool get isAuthenticated => state.isAuthenticated;

  void setSession({required String? accessToken, required String? userId}) {
    final normalizedToken = accessToken?.trim().isEmpty ?? true
        ? null
        : accessToken!.trim();
    emit(AuthSessionState(accessToken: normalizedToken, userId: userId));
    _notifyListeners();
  }

  void clear() {
    emit(const AuthSessionState());
    _notifyListeners();
  }

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners.toList()) {
      listener();
    }
  }
}
