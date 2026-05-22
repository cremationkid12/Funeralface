import 'package:everroute/core/env.dart';
import 'package:everroute/core/network/api_client.dart';
import 'package:everroute/features/auth/auth_error_messages.dart';
import 'package:everroute/features/auth/auth_state.dart';
import 'package:everroute/services/auth_services.dart' as auth_services;
import 'package:flutter_bloc/flutter_bloc.dart';
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
      emit(AuthState(error: friendlyAuthError(e, AuthAction.login)));
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
    } catch (e) {
      emit(AuthState(error: friendlyAuthError(e, AuthAction.register)));
    }
  }

  Future<void> recoverPassword({required String email}) async {
    emit(const AuthState(busy: true));
    try {
      await _authServices.recoverPassword(email: email);
      emit(
        AuthState(
          info:
              'If an account exists for that email, a ${AppEnv.passwordResetOtpDigits}-digit code has been sent.',
        ),
      );
    } catch (e) {
      emit(AuthState(error: friendlyAuthError(e, AuthAction.recover)));
    }
  }

  /// Returns short-lived tokens after OTP verification (not persisted until
  /// [completePasswordReset] succeeds).
  Future<({String accessToken, String refreshToken})?> verifyPasswordResetOtp({
    required String email,
    required String code,
  }) async {
    emit(const AuthState(busy: true));
    try {
      final r = await _authServices.verifyPasswordResetOtp(
        email: email,
        token: code,
      );
      emit(const AuthState());
      return (accessToken: r.accessToken, refreshToken: r.refreshToken);
    } catch (e) {
      emit(AuthState(error: friendlyAuthError(e, AuthAction.verifyOtp)));
      return null;
    }
  }

  Future<void> completePasswordReset({
    required String accessToken,
    required String refreshToken,
    required String password,
    required ApiClient apiClient,
  }) async {
    emit(const AuthState(busy: true));
    try {
      final result = await _authServices.completePasswordReset(
        accessToken: accessToken,
        refreshToken: refreshToken,
        password: password,
      );
      await auth_services.ensureBackendProvisioned(
        apiClient,
        result.accessToken,
      );
      emit(const AuthState(success: true));
    } catch (e) {
      emit(AuthState(error: friendlyAuthError(e, AuthAction.completeReset)));
    }
  }

  Future<void> loginWithGoogle({required ApiClient apiClient}) async {
    emit(const AuthState(busy: true));
    try {
      final serverClientId = AppEnv.googleWebClientId.trim();
      if (serverClientId.isEmpty) {
        emit(
          const AuthState(
            error:
                'Google sign-in is currently unavailable. Please use email sign-in.',
          ),
        );
        return;
      }
      await _googleSignIn.initialize(serverClientId: serverClientId);
      GoogleSignInAccount? account;
      try {
        account = await _googleSignIn.attemptLightweightAuthentication();
      } catch (_) {
        account = null;
      }
      account ??= await _googleSignIn.authenticate();
      final auth = account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        emit(
          const AuthState(
            error:
                "We couldn't sign you in with Google. Please try again.",
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
      emit(AuthState(error: friendlyAuthError(e, AuthAction.google)));
    }
  }
}
