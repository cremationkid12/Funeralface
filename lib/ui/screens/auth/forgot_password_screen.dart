import 'package:flutter/material.dart';
import 'package:everroute/ui/screens/auth/widgets/auth_form_widgets.dart';
import 'package:everroute/ui/widgets/app_buttons.dart';
import 'package:go_router/go_router.dart';

/// Forgot password — email entry (UI only).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _onSendOtp() {
    context.push('/auth/verify-code');
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      _initialized = true;
      final email = GoRouterState.of(context).uri.queryParameters['email'];
      if (email != null && email.isNotEmpty) {
        _email.text = email;
      }
    }

    return AuthFlowScaffold(
      title: 'Forgot Password',
      subtitle: 'Enter your email address to reset your password',
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthFieldLabel('Email Address'),
          const SizedBox(height: 6),
          AuthTextField(
            controller: _email,
            hint: 'zainabali@example.com',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _onSendOtp(),
          ),
          const SizedBox(height: 20),
          AppPrimaryButton(label: 'Send OTP', onPressed: _onSendOtp),
        ],
      ),
    );
  }
}
