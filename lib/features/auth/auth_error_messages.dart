import 'package:everroute/core/network/api_client.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// The auth flow that produced an error. Used to pick a more
/// helpful, contextual user-facing message.
enum AuthAction {
  login,
  register,
  google,
  apple,
  recover,
  verifyOtp,
  completeReset,
}

/// Turn a raw exception coming from the auth services into a polished,
/// user-facing message. Falls back to a generic, action-specific message
/// so we never surface developer-style strings like
/// `ApiException(statusCode: 401, code: unauthorized, message: ...)`.
String friendlyAuthError(Object error, AuthAction action) {
  if (error is ApiException) {
    return _fromApiException(error, action);
  }
  if (error is GoogleSignInException) {
    return _fromGoogleSignInException(error);
  }
  if (error is SignInWithAppleAuthorizationException) {
    return _fromAppleAuthorizationException(error);
  }
  // Strip Dart's standard `Exception: ` prefix if present.
  final raw = error.toString();
  final cleaned = raw.startsWith('Exception: ')
      ? raw.substring('Exception: '.length)
      : raw;
  return _fromMessage(cleaned, action);
}

/// Maps the typed exception thrown by `package:google_sign_in` (7.x) into
/// a friendly message.
///
/// Per the google_sign_in_android troubleshooting docs, several
/// configuration errors (wrong SHA-1, wrong package name, mismatched
/// `serverClientId`, missing web OAuth client in `google-services.json`)
/// surface as `canceled` with a non-empty description and are
/// indistinguishable from the user actually pressing back. We use the
/// description to disambiguate where possible.
String _fromGoogleSignInException(GoogleSignInException e) {
  final desc = (e.description ?? '').toLowerCase().trim();
  switch (e.code) {
    case GoogleSignInExceptionCode.userMismatch:
      return 'The Google account on this device is not the same as the one used to sign in. Please sign in with the correct account.';
    case GoogleSignInExceptionCode.canceled:
      // Empty description → most likely a real user cancellation.
      if (desc.isEmpty || desc == 'cancelled' || desc == 'canceled') {
        return 'Sign-in was cancelled.';
      }
      return _googleSignInUnavailableMessage();
    case GoogleSignInExceptionCode.interrupted:
      return 'Google sign-in was interrupted. Please try again.';
    case GoogleSignInExceptionCode.clientConfigurationError:
    case GoogleSignInExceptionCode.providerConfigurationError:
      return 'Google sign-in is currently unavailable. Please use email '
          'sign-in instead.';
    case GoogleSignInExceptionCode.uiUnavailable:
      return "We couldn't open the Google sign-in screen. Please try again.";
    case GoogleSignInExceptionCode.unknownError:
      return _googleSignInUnavailableMessage();
  }
}

/// Honest message for the ambiguous Google sign-in failure that could be
/// either a missing Google account on the device OR a configuration
/// mismatch — both surface identically through CredentialManager.
String _googleSignInUnavailableMessage() {
  return "Couldn't sign you in with Google. Make sure a Google account is "
      "added on this device, or use email sign-in instead.";
}

String _fromAppleAuthorizationException(SignInWithAppleAuthorizationException e) {
  if (e.code == AuthorizationErrorCode.canceled) {
    return 'Sign-in was cancelled.';
  }
  if (e.code == AuthorizationErrorCode.failed) {
    return "We couldn't sign you in with Apple. Please try again.";
  }
  return 'Sign in with Apple is currently unavailable. Please use email '
      'or Google sign-in instead.';
}

String _fromApiException(ApiException e, AuthAction action) {
  switch (e.code?.toLowerCase()) {
    case 'service_unavailable':
      return 'Service is temporarily unavailable. Please try again in a few minutes.';
    case 'rate_limited':
      return 'Too many attempts. Please wait a moment before trying again.';
    case 'unauthorized':
      switch (action) {
        case AuthAction.login:
          return 'Incorrect email or password. Please try again.';
        case AuthAction.google:
          return "We couldn't sign you in with Google. Please try again.";
        case AuthAction.apple:
          return "We couldn't sign you in with Apple. Please try again.";
        case AuthAction.register:
          return "We couldn't create your account. Please try again.";
        case AuthAction.recover:
          return 'Your session has expired. Please log in again.';
        case AuthAction.verifyOtp:
          return 'That code is incorrect or has expired. Try again or request a new code.';
        case AuthAction.completeReset:
          return 'This session is invalid or has expired. Request a new code from the login screen.';
      }
    case 'bad_request':
      switch (action) {
        case AuthAction.register:
          return 'Please enter your name, a valid email, and a password of at least 8 characters.';
        case AuthAction.login:
          return 'Please enter a valid email and password.';
        case AuthAction.recover:
          return 'Please enter a valid email address.';
        case AuthAction.verifyOtp:
          return 'Enter the verification code from your email.';
        case AuthAction.completeReset:
          return 'Please use a password of at least 8 characters.';
        case AuthAction.google:
          return "We couldn't read your Google credentials. Please try again.";
        case AuthAction.apple:
          return "We couldn't read your Apple credentials. Please try again.";
      }
    case 'provision_failed':
      return "We couldn't finish setting up your account. Please try again.";
  }
  // Unknown code → try to humanise the raw message text.
  return _fromMessage(e.message, action);
}

String _fromMessage(String message, AuthAction action) {
  final m = message.toLowerCase();

  if (m.contains('already registered') || m.contains('user already')) {
    return 'An account with this email already exists. Please log in instead.';
  }
  if (m.contains('invalid login credentials') ||
      m.contains('invalid email or password') ||
      m.contains('invalid credentials')) {
    return 'Incorrect email or password. Please try again.';
  }
  if (m.contains('email not confirmed')) {
    return 'Please verify your email address before logging in.';
  }
  if (m.contains('password should be at least') ||
      m.contains('password is too short')) {
    return 'Your password is too short. Please use at least 8 characters.';
  }
  if (m.contains('rate limit')) {
    return 'Too many attempts. Please wait a moment before trying again.';
  }
  if (m.contains('socketexception') ||
      m.contains('failed host lookup') ||
      m.contains('connection refused') ||
      m.contains('connection timed out') ||
      m.contains('network is unreachable') ||
      m.contains('no internet')) {
    return 'Network error. Please check your connection and try again.';
  }
  if (m.contains('no credential available') ||
      m.contains('no google account') ||
      m.contains('credential not found')) {
    return _googleSignInUnavailableMessage();
  }
  if (m.contains('did not return a complete auth session')) {
    return "We couldn't complete sign-in. Please try again.";
  }
  if (m.contains('user cancelled') || m.contains('user canceled')) {
    return 'Sign-in was cancelled.';
  }

  // Generic fallback per action.
  switch (action) {
    case AuthAction.login:
      return "We couldn't log you in. Please try again.";
    case AuthAction.register:
      return "We couldn't create your account. Please try again.";
    case AuthAction.google:
      return "We couldn't sign you in with Google. Please try again.";
    case AuthAction.apple:
      return "We couldn't sign you in with Apple. Please try again.";
    case AuthAction.recover:
      return "We couldn't send the reset email. Please try again.";
    case AuthAction.verifyOtp:
      return "We couldn't verify that code. Please try again.";
    case AuthAction.completeReset:
      return "We couldn't update your password. Please try again or request a new reset link.";
  }
}
