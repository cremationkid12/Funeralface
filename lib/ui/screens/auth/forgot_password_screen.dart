import 'package:everroute/ui/screens/auth/widgets/auth_field_label.dart';
import 'package:everroute/ui/screens/auth/widgets/auth_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:everroute/features/auth/auth_cubit.dart';
import 'package:everroute/features/auth/auth_state.dart';
import 'package:everroute/ui/screens/auth/widgets/auth_flow_scaffold.dart';
import 'package:everroute/ui/widgets/app_buttons.dart';
import 'package:everroute/ui/widgets/everroute_snack_bar.dart';
import 'package:go_router/go_router.dart';

final RegExp _roughEmailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

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

  Future<void> _onSubmit() async {
    final email = _email.text.trim();
    if (email.isEmpty || !_roughEmailPattern.hasMatch(email)) {
      EverrouteSnackBar.info(context, 'Please enter a valid email address.');
      return;
    }
    FocusScope.of(context).unfocus();
    await context.read<AuthCubit>().recoverPassword(email: email);
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

    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (prev, curr) =>
          prev.error != curr.error ||
          prev.info != curr.info ||
          prev.busy != curr.busy,
      listener: (context, state) {
        if (state.error != null) {
          EverrouteSnackBar.error(context, state.error!);
          context.read<AuthCubit>().clearMessages();
        } else if (state.info != null) {
          final msg = state.info!;
          context.read<AuthCubit>().clearMessages();
          if (msg.contains('code has been sent')) {
            final qp = '?email=${Uri.encodeQueryComponent(_email.text.trim())}';
            if (mounted) context.push('/auth/verify-code$qp');
          } else {
            EverrouteSnackBar.info(context, msg);
          }
        }
      },
      builder: (context, state) => AuthFlowScaffold(
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
              onSubmitted: (_) {
                if (!state.busy) _onSubmit();
              },
            ),
            const SizedBox(height: 20),
            AppPrimaryButton(
              label: 'Send code',
              busy: state.busy,
              onPressed: state.busy ? null : () => _onSubmit(),
            ),
          ],
        ),
      ),
    );
  }
}
