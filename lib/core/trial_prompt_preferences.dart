import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists which trial-related dialogs the user has already seen.
class TrialPromptPreferences {
  TrialPromptPreferences({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _pendingWelcomeKey = 'trial_pending_welcome';
  static const _welcomeShownPrefix = 'trial_welcome_shown_';
  static const _expiryWarnedPrefix = 'trial_expiry_warned_';

  Future<void> markWelcomePendingAfterSignup() async {
    await _storage.write(key: _pendingWelcomeKey, value: '1');
  }

  Future<bool> consumePendingWelcome() async {
    final value = await _storage.read(key: _pendingWelcomeKey);
    if (value != '1') return false;
    await _storage.delete(key: _pendingWelcomeKey);
    return true;
  }

  Future<bool> hasShownWelcome(String orgId) async {
    if (orgId.trim().isEmpty) return false;
    return (await _storage.read(key: '$_welcomeShownPrefix$orgId')) == '1';
  }

  Future<void> markWelcomeShown(String orgId) async {
    if (orgId.trim().isEmpty) return;
    await _storage.write(key: '$_welcomeShownPrefix$orgId', value: '1');
  }

  Future<bool> hasShownExpiryWarningToday(String orgId) async {
    if (orgId.trim().isEmpty) return false;
    final today = DateTime.now().toIso8601String().split('T').first;
    return (await _storage.read(key: '$_expiryWarnedPrefix$orgId')) == today;
  }

  Future<void> markExpiryWarningShownToday(String orgId) async {
    if (orgId.trim().isEmpty) return;
    final today = DateTime.now().toIso8601String().split('T').first;
    await _storage.write(key: '$_expiryWarnedPrefix$orgId', value: today);
  }
}
