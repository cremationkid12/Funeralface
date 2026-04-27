import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:everroute/core/network/api_client.dart';
import 'package:everroute/features/auth/auth_state.dart';
import 'package:everroute/services/auth_services.dart'
    as auth_services;
import 'package:google_sign_in/google_sign_in.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required auth_services.AuthServices authServices,
    required GoogleSignIn googleSignIn,
  }) : _authServices = authServices,
       _googleSignIn = googleSignIn,
       super(const AuthState());

  final auth_services.AuthServices _authServices;
  final GoogleSignIn _googleSignIn;

  void clearMessages() =>
      emit(state.copyWith(clearError: true, clearInfo: true, success: false));

  void setError(String message) =>
      emit(state.copyWith(error: message, clearInfo: true, success: false));

  Future<void> login({
    required String email,
    required String password,
    required ApiClient apiClient,
    String? inviteToken,
  }) async {
    emit(const AuthState(busy: true));
    try {
      final result = await _authServices.login(
        email: email,
        password: password,
        inviteToken: inviteToken,
      );
      if ((inviteToken ?? '').trim().isNotEmpty) {
        await auth_services.acceptInvite(
          apiClient,
          result.accessToken,
          inviteToken!.trim(),
        );
      }
      await auth_services.ensureBackendProvisioned(
        apiClient,
        result.accessToken,
      );
      emit(const AuthState(success: true));
    } catch (e) {
      emit(AuthState(error: e.toString()));
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required ApiClient apiClient,
    String? inviteToken,
  }) async {
    emit(const AuthState(busy: true));
    try {
      final result = await _authServices.register(
        name: name,
        email: email,
        password: password,
        inviteToken: inviteToken,
      );
      if ((inviteToken ?? '').trim().isNotEmpty) {
        await auth_services.acceptInvite(
          apiClient,
          result.accessToken,
          inviteToken!.trim(),
        );
      }
      await auth_services.ensureBackendProvisioned(
        apiClient,
        result.accessToken,
      );
      emit(const AuthState(success: true));
    } on ApiException catch (e) {
      emit(AuthState(error: e.toString()));
    } catch (e) {
      emit(AuthState(error: e.toString()));
    }
  }

  Future<void> recoverPassword({required String email}) async {
    emit(const AuthState(busy: true));
    try {
      await _authServices.recoverPassword(email: email);
      emit(
        const AuthState(
          info: 'Password reset email sent if the account exists.',
        ),
      );
    } catch (e) {
      emit(AuthState(error: e.toString()));
    }
  }

  Future<void> loginWithGoogle({required ApiClient apiClient}) async {
    emit(const AuthState(busy: true));
    try {
      await _googleSignIn.initialize();
      final account = await _googleSignIn.authenticate();
      final auth = account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        emit(
          const AuthState(
            error: 'Google sign-in failed to provide an ID token.',
          ),
        );
        return;
      }
      final result = await _authServices.loginWithGoogle(idToken: idToken);
      await auth_services.ensureBackendProvisioned(
        apiClient,
        result.accessToken,
      );
      emit(const AuthState(success: true));
    } catch (e) {
      emit(AuthState(error: e.toString()));
    }
  }
}
