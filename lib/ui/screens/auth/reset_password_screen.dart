import 'package:everroute/ui/screens/auth/widgets/auth_field_label.dart';
import 'package:everroute/ui/screens/auth/widgets/auth_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:everroute/core/network/api_client.dart';
import 'package:everroute/core/theme/app_theme.dart';
import 'package:everroute/features/auth/auth_cubit.dart';
import 'package:everroute/features/auth/auth_state.dart';
import 'package:everroute/ui/screens/auth/widgets/auth_flow_scaffold.dart';
import 'package:everroute/ui/widgets/app_buttons.dart';
import 'package:everroute/ui/widgets/everroute_snack_bar.dart';
import 'package:go_router/go_router.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    this.recoveryAccessToken,
    this.recoveryRefreshToken,
  });

  /// From in-app navigation after OTP verification ([GoRouterState.extra]).
  final String? recoveryAccessToken;
  final String? recoveryRefreshToken;

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

  Future<void> _submit() async {
    final at = widget.recoveryAccessToken?.trim();
    final rt = widget.recoveryRefreshToken?.trim();
    if (at == null || at.isEmpty || rt == null || rt.isEmpty) {
      EverrouteSnackBar.info(
        context,
        'Continue from Forgot password (code) or open the reset link from your email on this device.',
      );
      return;
    }

    final p = _password.text;
    final c = _confirmPassword.text;
    if (p.length < 8) {
      EverrouteSnackBar.info(
        context,
        'Password must be at least 8 characters.',
      );
      return;
    }
    if (p != c) {
      EverrouteSnackBar.info(context, 'Passwords do not match.');
      return;
    }

    FocusScope.of(context).unfocus();
    await context.read<AuthCubit>().completePasswordReset(
          accessToken: at,
          refreshToken: rt,
          password: p,
          apiClient: context.read<ApiClient>(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final hasTokens = (widget.recoveryAccessToken ?? '').trim().isNotEmpty &&
        (widget.recoveryRefreshToken ?? '').trim().isNotEmpty;

    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (prev, curr) =>
          prev.error != curr.error || prev.success != curr.success,
      listener: (context, state) {
        if (state.error != null) {
          EverrouteSnackBar.error(context, state.error!);
          context.read<AuthCubit>().clearMessages();
        } else if (state.success) {
          EverrouteSnackBar.info(context, 'Password updated. Welcome back!');
          context.read<AuthCubit>().clearMessages();
          context.go('/dashboard');
        }
      },
      builder: (context, state) => AuthFlowScaffold(
        title: 'Enter New Password',
        subtitle: hasTokens
            ? 'Enter your new password'
            : 'Verify your email code or open the reset link from email first.',
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
              enabled: hasTokens && !state.busy,
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
              enabled: hasTokens && !state.busy,
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
            AppPrimaryButton(
              label: 'Reset Password',
              busy: state.busy,
              onPressed: (!hasTokens || state.busy) ? null : () => _submit(),
            ),
          ],
        ),
      ),
    );
  }
}
