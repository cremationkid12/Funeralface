import 'package:flutter/material.dart';
import 'package:everroute/ui/screens/auth/widgets/auth_form_widgets.dart';
import 'package:everroute/ui/widgets/app_buttons.dart';
import 'package:go_router/go_router.dart';

/// OTP verification step (UI only).
class VerificationCodeScreen extends StatefulWidget {
  const VerificationCodeScreen({super.key});

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  String _code = '';

  void _onSubmit() {
    context.push('/auth/reset-password');
  }

  @override
  Widget build(BuildContext context) {
    return AuthFlowScaffold(
      title: 'Enter Verification Code',
      subtitle: 'We have sent a code verification to your email address',
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthOtpInput(onChanged: (code) => setState(() => _code = code)),
          const SizedBox(height: 20),
          AppPrimaryButton(
            label: 'Submit',
            onPressed: _code.length == 5 ? _onSubmit : null,
          ),
        ],
      ),
    );
  }
}
