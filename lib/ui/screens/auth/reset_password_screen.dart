import 'package:flutter/material.dart';
import 'package:everroute/core/theme/app_theme.dart';
import 'package:everroute/ui/screens/auth/widgets/auth_form_widgets.dart';
import 'package:everroute/ui/widgets/app_buttons.dart';
import 'package:go_router/go_router.dart';

/// Set a new password after verification (UI only).
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmVisible = false;

  @override
  void dispose() {
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _onReset() {
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return AuthFlowScaffold(
      title: 'Enter New Password',
      subtitle: 'Enter your new password',
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthFieldLabel('New Password'),
          const SizedBox(height: 6),
          AuthTextField(
            controller: _password,
            hint: '••••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: !_passwordVisible,
            autofillHints: const [AutofillHints.newPassword],
            suffixIcon: IconButton(
              icon: Icon(
                _passwordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _passwordVisible = !_passwordVisible),
            ),
          ),
          const SizedBox(height: 14),
          const AuthFieldLabel('Re-Enter New Password'),
          const SizedBox(height: 6),
          AuthTextField(
            controller: _confirmPassword,
            hint: '••••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: !_confirmVisible,
            autofillHints: const [AutofillHints.newPassword],
            suffixIcon: IconButton(
              icon: Icon(
                _confirmVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _confirmVisible = !_confirmVisible),
            ),
          ),
          const SizedBox(height: 20),
          AppPrimaryButton(label: 'Reset Password', onPressed: _onReset),
        ],
      ),
    );
  }
}
