import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:everroute/core/env.dart';
import 'package:everroute/core/network/api_client.dart';
import 'package:everroute/core/theme/app_theme.dart';
import 'package:everroute/features/auth/auth_cubit.dart';
import 'package:everroute/features/auth/auth_state.dart';
import 'package:everroute/ui/screens/auth/widgets/auth_field_label.dart';
import 'package:everroute/ui/screens/auth/widgets/auth_flow_scaffold.dart';
import 'package:everroute/ui/screens/auth/widgets/auth_section_card.dart';
import 'package:everroute/ui/screens/auth/widgets/auth_text_field.dart';
import 'package:everroute/ui/widgets/app_buttons.dart';
import 'package:everroute/ui/widgets/everroute_snack_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  void initState() {
    super.initState();
    // Drop any stale auth message left over from a previous screen visit
    // so the snackbar listener only fires for fresh, in-screen events.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthCubit>().clearMessages();
    });
  }

  // true = Login view, false = Signup view
  bool _isLogin = true;

  // Login fields
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  bool _loginRememberMe = false;
  bool _loginPasswordVisible = false;

  // Signup fields
  final _signupName = TextEditingController();
  final _signupEmail = TextEditingController();
  final _signupPassword = TextEditingController();
  bool _signupPasswordVisible = false;
  bool _signupAcceptTerms = false;
  bool _inviteInitialized = false;
  String? _inviteToken;

  AuthCubit get _authCubit => context.read<AuthCubit>();

  @override
  void dispose() {
    _loginEmail.dispose();
    _loginPassword.dispose();
    _signupName.dispose();
    _signupEmail.dispose();
    _signupPassword.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() => _isLogin = !_isLogin);
    _authCubit.clearMessages();
  }

  Future<void> _doLogin() async {
    await _authCubit.login(
      email: _loginEmail.text.trim(),
      password: _loginPassword.text,
      apiClient: context.read<ApiClient>(),
      inviteToken: _inviteToken,
    );
    if (!mounted) return;
    if (_authCubit.state.success) {
      context.go('/dashboard');
    }
  }

  Future<void> _doSignup() async {
    if (!_signupAcceptTerms) {
      _authCubit.setError('Please accept the Terms of Use.');
      return;
    }
    final name = _signupName.text.trim();
    if (name.isEmpty) {
      _authCubit.setError('Please enter your name.');
      return;
    }
    await _authCubit.register(
      name: name,
      email: _signupEmail.text.trim(),
      password: _signupPassword.text,
      apiClient: context.read<ApiClient>(),
      inviteToken: _inviteToken,
    );
    if (!mounted) return;
    if (_authCubit.state.success) {
      context.go('/dashboard');
    }
  }

  void _openForgotPassword() {
    final email = _loginEmail.text.trim();
    final qp = email.isNotEmpty
        ? '?email=${Uri.encodeQueryComponent(email)}'
        : '';
    context.push('/auth/forgot-password$qp');
  }

  Future<void> _onGoogleTap() async {
    await _authCubit.loginWithGoogle(apiClient: context.read<ApiClient>());
    if (!mounted) return;
    if (_authCubit.state.success) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_inviteInitialized) {
      _inviteInitialized = true;
      final qp = GoRouterState.of(context).uri.queryParameters;
      final token = qp['invite_token']?.trim();
      final email = qp['email']?.trim();
      if (token != null && token.isNotEmpty) {
        _inviteToken = token;
        _isLogin = false;
      }
      if (email != null && email.isNotEmpty) {
        _loginEmail.text = email;
        _signupEmail.text = email;
      }
    }

    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (prev, curr) =>
          prev.error != curr.error || prev.info != curr.info,
      listener: (context, state) {
        if (state.error != null) {
          EverrouteSnackBar.error(context, state.error!);
          context.read<AuthCubit>().clearMessages();
        } else if (state.info != null) {
          EverrouteSnackBar.info(context, state.info!);
          context.read<AuthCubit>().clearMessages();
        }
      },
      builder: (context, authState) => AuthFlowScaffold(
        showBackButton: false,
        scrollHeader: Center(
          child: SvgPicture.asset('assets/landing logo.svg', height: 100),
        ),
        title: _isLogin ? 'Hello, Welcome Back' : 'Signup',
        subtitle: _isLogin
            ? 'Login to your account below'
            : 'Enter your details below to create your account.',
        body: _isLogin
            ? _LoginForm(
                emailController: _loginEmail,
                passwordController: _loginPassword,
                passwordVisible: _loginPasswordVisible,
                rememberMe: _loginRememberMe,
                busy: authState.busy,
                onTogglePassword: () => setState(
                  () => _loginPasswordVisible = !_loginPasswordVisible,
                ),
                onRememberMe: (v) =>
                    setState(() => _loginRememberMe = v ?? false),
                onForgotPassword: _openForgotPassword,
                onSubmit: _doLogin,
              )
            : _SignupForm(
                nameController: _signupName,
                emailController: _signupEmail,
                passwordController: _signupPassword,
                passwordVisible: _signupPasswordVisible,
                acceptTerms: _signupAcceptTerms,
                busy: authState.busy,
                onTogglePassword: () => setState(
                  () => _signupPasswordVisible = !_signupPasswordVisible,
                ),
                onAcceptTerms: (v) =>
                    setState(() => _signupAcceptTerms = v ?? false),
                onSubmit: _doSignup,
              ),
        belowBody: AuthSectionCard(
          child: Column(
            children: [
              _OrDivider(label: _isLogin ? 'Or Login with' : 'Or Signup with'),
              const SizedBox(height: 16),
              _SocialButton(
                label: 'Google',
                icon: _GoogleIcon(),
                onTap: authState.busy ? () {} : _onGoogleTap,
              ),
              const SizedBox(height: 16),
              _SwitchModeText(isLogin: _isLogin, onSwitch: _switchMode),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Login form ─────────────────────────────────────────────────────────────────

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.emailController,
    required this.passwordController,
    required this.passwordVisible,
    required this.rememberMe,
    required this.busy,
    required this.onTogglePassword,
    required this.onRememberMe,
    required this.onForgotPassword,
    required this.onSubmit,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool passwordVisible;
  final bool rememberMe;
  final bool busy;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool?> onRememberMe;
  final VoidCallback onForgotPassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthFieldLabel('Email Address'),
        const SizedBox(height: 6),
        AuthTextField(
          controller: emailController,
          hint: 'zainabali@example.com',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 14),
        const AuthFieldLabel('Password'),
        const SizedBox(height: 6),
        AuthTextField(
          controller: passwordController,
          hint: '••••••••••',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: !passwordVisible,
          suffixIcon: IconButton(
            icon: Icon(
              passwordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onPressed: onTogglePassword,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: rememberMe,
                onChanged: onRememberMe,
                activeColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Remember Me',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: busy ? null : onForgotPassword,
              child: Text(
                'Forgot Password?',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AppPrimaryButton(label: 'Login', busy: busy, onPressed: onSubmit),
      ],
    );
  }
}

// ── Signup form ────────────────────────────────────────────────────────────────

class _SignupForm extends StatelessWidget {
  const _SignupForm({
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.passwordVisible,
    required this.acceptTerms,
    required this.busy,
    required this.onTogglePassword,
    required this.onAcceptTerms,
    required this.onSubmit,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool passwordVisible;
  final bool acceptTerms;
  final bool busy;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool?> onAcceptTerms;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthFieldLabel('Name'),
        const SizedBox(height: 6),
        AuthTextField(
          controller: nameController,
          hint: 'Zainab Ali',
          prefixIcon: Icons.person_outline_rounded,
          keyboardType: TextInputType.name,
          autofillHints: const [AutofillHints.name],
        ),
        const SizedBox(height: 14),
        const AuthFieldLabel('Email Address'),
        const SizedBox(height: 6),
        AuthTextField(
          controller: emailController,
          hint: 'zainabali@example.com',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 14),
        const AuthFieldLabel('Password'),
        const SizedBox(height: 6),
        AuthTextField(
          controller: passwordController,
          hint: '••••••••••',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: !passwordVisible,
          suffixIcon: IconButton(
            icon: Icon(
              passwordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onPressed: onTogglePassword,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: acceptTerms,
                onChanged: onAcceptTerms,
                activeColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                  ),
                  children: [
                    const TextSpan(text: 'I Accept the '),
                    TextSpan(
                      text: 'Terms of Use',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          final uri = Uri.parse(AppEnv.termsOfUseUrl);
                          try {
                            final opened = await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                            if (!opened && context.mounted) {
                              EverrouteSnackBar.info(
                                context,
                                'Could not open Terms of Use.',
                              );
                            }
                          } catch (_) {
                            if (context.mounted) {
                              EverrouteSnackBar.info(
                                context,
                                'Could not open Terms of Use.',
                              );
                            }
                          }
                        },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AppPrimaryButton(label: 'Signup', busy: busy, onPressed: onSubmit),
      ],
    );
  }
}

// ── Reusable sub-widgets ───────────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(endIndent: 12)),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const Expanded(child: Divider(indent: 12)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchModeText extends StatelessWidget {
  const _SwitchModeText({required this.isLogin, required this.onSwitch});

  final bool isLogin;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        children: [
          TextSpan(
            text: isLogin
                ? "Didn't have an account? "
                : 'Already have an account? ',
          ),
          TextSpan(
            text: isLogin ? 'Signup' : 'Login',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
            recognizer: TapGestureRecognizer()..onTap = onSwitch,
          ),
        ],
      ),
    );
  }
}

// ── Social brand icons (inline SVG paths) ─────────────────────────────────────

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 20;
    final paint = Paint()..style = PaintingStyle.fill;

    // Red arc (top-right)
    paint.color = const Color(0xFFEA4335);
    final path1 = Path()
      ..moveTo(10 * s, 4.18 * s)
      ..lineTo(12.9 * s, 4.18 * s)
      ..cubicTo(14.13 * s, 4.18 * s, 15.25 * s, 4.62 * s, 16.13 * s, 5.37 * s)
      ..lineTo(18.59 * s, 2.91 * s)
      ..cubicTo(16.98 * s, 1.37 * s, 14.62 * s, 0.36 * s, 12 * s, 0.36 * s)
      ..cubicTo(7.99 * s, 0.36 * s, 4.6 * s, 2.75 * s, 3.01 * s, 6.17 * s)
      ..lineTo(5.95 * s, 8.47 * s)
      ..cubicTo(6.58 * s, 6.08 * s, 8.1 * s, 4.18 * s, 10 * s, 4.18 * s)
      ..close();
    canvas.drawPath(path1, paint);

    // Blue arc (bottom-right)
    paint.color = const Color(0xFF4285F4);
    final path2 = Path()
      ..moveTo(19.64 * s, 10.2 * s)
      ..cubicTo(19.64 * s, 9.55 * s, 19.58 * s, 8.96 * s, 19.47 * s, 8.36 * s)
      ..lineTo(10 * s, 8.36 * s)
      ..lineTo(10 * s, 11.85 * s)
      ..lineTo(15.44 * s, 11.85 * s)
      ..cubicTo(
        15.18 * s,
        13.12 * s,
        14.48 * s,
        14.19 * s,
        13.45 * s,
        14.93 * s,
      )
      ..lineTo(16.35 * s, 17.1 * s)
      ..cubicTo(18.22 * s, 15.36 * s, 19.64 * s, 12.91 * s, 19.64 * s, 10.2 * s)
      ..close();
    canvas.drawPath(path2, paint);

    // Yellow arc (bottom-left)
    paint.color = const Color(0xFFFBBC05);
    final path3 = Path()
      ..moveTo(5.95 * s, 11.53 * s)
      ..cubicTo(5.77 * s, 10.97 * s, 5.68 * s, 10.39 * s, 5.68 * s, 10 * s)
      ..cubicTo(5.68 * s, 9.61 * s, 5.77 * s, 9.03 * s, 5.95 * s, 8.47 * s)
      ..lineTo(3.01 * s, 6.17 * s)
      ..cubicTo(2.22 * s, 7.73 * s, 1.78 * s, 9.81 * s, 1.78 * s, 10 * s)
      ..cubicTo(1.78 * s, 11.31 * s, 2.2 * s, 12.54 * s, 3.01 * s, 13.83 * s)
      ..lineTo(5.95 * s, 11.53 * s)
      ..close();
    canvas.drawPath(path3, paint);

    // Green arc (top-left)
    paint.color = const Color(0xFF34A853);
    final path4 = Path()
      ..moveTo(10 * s, 19.64 * s)
      ..cubicTo(12.67 * s, 19.64 * s, 14.9 * s, 18.77 * s, 16.35 * s, 17.1 * s)
      ..lineTo(13.45 * s, 14.93 * s)
      ..cubicTo(12.62 * s, 15.48 * s, 11.38 * s, 15.82 * s, 10 * s, 15.82 * s)
      ..cubicTo(8.1 * s, 15.82 * s, 6.58 * s, 13.92 * s, 5.95 * s, 11.53 * s)
      ..lineTo(3.01 * s, 13.83 * s)
      ..cubicTo(4.6 * s, 17.25 * s, 7.99 * s, 19.64 * s, 10 * s, 19.64 * s)
      ..close();
    canvas.drawPath(path4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
