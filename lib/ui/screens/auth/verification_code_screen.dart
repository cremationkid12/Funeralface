import 'package:everroute/core/env.dart';
import 'package:everroute/ui/screens/auth/widgets/auth_otp_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:everroute/features/auth/auth_cubit.dart';
import 'package:everroute/features/auth/auth_state.dart';
import 'package:everroute/ui/screens/auth/widgets/auth_flow_scaffold.dart';
import 'package:everroute/ui/widgets/app_buttons.dart';
import 'package:everroute/ui/widgets/everroute_snack_bar.dart';
import 'package:go_router/go_router.dart';

/// Enters the emailed OTP for password reset (length from [AppEnv.passwordResetOtpDigits]).
class VerificationCodeScreen extends StatefulWidget {
  const VerificationCodeScreen({super.key});

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  String _code = '';

  Future<void> _onSubmit() async {
    final email =
        GoRouterState.of(context).uri.queryParameters['email']?.trim() ?? '';
    if (email.isEmpty) {
      EverrouteSnackBar.info(context, 'Go back and enter your email first.');
      return;
    }
    final digits = AppEnv.passwordResetOtpDigits;
    final re = RegExp('^\\d{$digits}\$');
    if (_code.length != digits || !re.hasMatch(_code)) {
      EverrouteSnackBar.info(
        context,
        'Enter the $digits-digit code from your email.',
      );
      return;
    }
    final tokens = await context.read<AuthCubit>().verifyPasswordResetOtp(
          email: email,
          code: _code,
        );
    if (!mounted || tokens == null) return;
    context.push(
      '/auth/reset-password',
      extra: <String, String>{
        'access_token': tokens.accessToken,
        'refresh_token': tokens.refreshToken,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final email =
        GoRouterState.of(context).uri.queryParameters['email']?.trim() ?? '';

    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (prev, curr) => prev.error != curr.error,
      listener: (context, state) {
        if (state.error != null) {
          EverrouteSnackBar.error(context, state.error!);
          context.read<AuthCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        final digits = AppEnv.passwordResetOtpDigits;
        return AuthFlowScaffold(
          title: 'Enter Verification Code',
          subtitle: email.isEmpty
              ? 'We sent a $digits-digit code to your email.'
              : 'We sent a code to $email',
          onBack: () => context.pop(),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthOtpInput(
                length: digits,
                onChanged: (code) => setState(() => _code = code),
              ),
              const SizedBox(height: 20),
              AppPrimaryButton(
                label: 'Submit',
                busy: state.busy,
                onPressed: (_code.length == digits && !state.busy)
                    ? _onSubmit
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }
}
