import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:funeralface_mobile/app/session/auth_session.dart';
import 'package:funeralface_mobile/core/env.dart';
import 'package:funeralface_mobile/core/network/api_client.dart';
import 'package:funeralface_mobile/core/theme/app_theme.dart';
import 'package:funeralface_mobile/features/auth/backend_provision.dart';
import 'package:funeralface_mobile/features/auth/supabase_auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
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

  bool _busy = false;
  String? _error;
  String? _info;

  SupabaseAuthService get _auth =>
      SupabaseAuthService(Supabase.instance.client);

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
    setState(() {
      _isLogin = !_isLogin;
      _error = null;
      _info = null;
    });
  }

  Future<void> _doLogin() async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await _auth.login(
        email: _loginEmail.text.trim(),
        password: _loginPassword.text,
      );
      if (!mounted) return;
      final token = AuthSession.instance.accessToken;
      if (token != null && token.isNotEmpty) {
        await ensureBackendProvisioned(context.read<ApiClient>(), token);
      }
      if (!mounted) return;
      context.go('/dashboard');
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _doSignup() async {
    if (!_signupAcceptTerms) {
      setState(() => _error = 'Please accept the Terms & Conditions.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await _auth.register(
        email: _signupEmail.text.trim(),
        password: _signupPassword.text,
      );
      if (!mounted) return;
      final token = AuthSession.instance.accessToken;
      if (token != null && token.isNotEmpty) {
        await ensureBackendProvisioned(context.read<ApiClient>(), token);
      }
      if (!mounted) return;
      context.go('/dashboard');
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openForgotPassword() async {
    final emailController =
        TextEditingController(text: _loginEmail.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => _ForgotPasswordDialog(controller: emailController),
    );
    emailController.dispose();
    if (!mounted || email == null || email.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await _auth.recoverPassword(email: email);
      if (!mounted) return;
      setState(() {
        _info = 'Password reset email sent if the account exists.';
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onSocialTap(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$provider sign-in coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AppEnv.hasSupabaseAuthConfig) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Supabase auth is not configured.\nSet SUPABASE_URL and SUPABASE_ANON_KEY.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Logo ──────────────────────────────────────────────────────
              Center(
                child: SvgPicture.asset(
                  'assets/landing logo.svg',
                  height: 100,
                ),
              ),
              const SizedBox(height: 24),

              // ── Heading card ──────────────────────────────────────────────
              _SectionCard(
                child: _isLogin ? _LoginHeading() : _SignupHeading(),
              ),
              const SizedBox(height: 16),

              // ── Form card ─────────────────────────────────────────────────
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Error / info banners
                    if (_error != null) ...[
                      _StatusBanner(message: _error!, isError: true),
                      const SizedBox(height: 12),
                    ],
                    if (_info != null) ...[
                      _StatusBanner(message: _info!, isError: false),
                      const SizedBox(height: 12),
                    ],

                    if (_isLogin)
                      _LoginForm(
                        emailController: _loginEmail,
                        passwordController: _loginPassword,
                        passwordVisible: _loginPasswordVisible,
                        rememberMe: _loginRememberMe,
                        busy: _busy,
                        onTogglePassword: () => setState(
                            () => _loginPasswordVisible = !_loginPasswordVisible),
                        onRememberMe: (v) =>
                            setState(() => _loginRememberMe = v ?? false),
                        onForgotPassword: _openForgotPassword,
                        onSubmit: _doLogin,
                      )
                    else
                      _SignupForm(
                        nameController: _signupName,
                        emailController: _signupEmail,
                        passwordController: _signupPassword,
                        passwordVisible: _signupPasswordVisible,
                        acceptTerms: _signupAcceptTerms,
                        busy: _busy,
                        onTogglePassword: () => setState(() =>
                            _signupPasswordVisible = !_signupPasswordVisible),
                        onAcceptTerms: (v) =>
                            setState(() => _signupAcceptTerms = v ?? false),
                        onSubmit: _doSignup,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Social login card ─────────────────────────────────────────
              _SectionCard(
                child: Column(
                  children: [
                    _OrDivider(label: _isLogin ? 'Or Login with' : 'Or Signup with'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _SocialButton(
                            label: 'Google',
                            icon: _GoogleIcon(),
                            onTap: () => _onSocialTap('Google'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SocialButton(
                            label: 'Facebook',
                            icon: _FacebookIcon(),
                            onTap: () => _onSocialTap('Facebook'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SwitchModeText(
                      isLogin: _isLogin,
                      onSwitch: _switchMode,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Heading widgets ────────────────────────────────────────────────────────────

class _LoginHeading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, Welcome Back',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Login to your account below',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _SignupHeading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Signup',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Enter your details below to create your account.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
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
        _FieldLabel('Email Address'),
        const SizedBox(height: 6),
        _AppTextField(
          controller: emailController,
          hint: 'zainabali@example.com',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 14),
        _FieldLabel('Password'),
        const SizedBox(height: 6),
        _AppTextField(
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
        _PrimaryButton(
          label: 'Login',
          busy: busy,
          onPressed: onSubmit,
        ),
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
        _FieldLabel('Name'),
        const SizedBox(height: 6),
        _AppTextField(
          controller: nameController,
          hint: 'Zainab Ali',
          prefixIcon: Icons.person_outline_rounded,
          keyboardType: TextInputType.name,
          autofillHints: const [AutofillHints.name],
        ),
        const SizedBox(height: 14),
        _FieldLabel('Email Address'),
        const SizedBox(height: 6),
        _AppTextField(
          controller: emailController,
          hint: 'zainabali@example.com',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 14),
        _FieldLabel('Password'),
        const SizedBox(height: 6),
        _AppTextField(
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
                      text: 'Terms & Conditions',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Terms & Conditions coming soon.'),
                            ),
                          );
                        },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _PrimaryButton(
          label: 'Signup',
          busy: busy,
          onPressed: onSubmit,
        ),
      ],
    );
  }
}

// ── Forgot password dialog ─────────────────────────────────────────────────────

class _ForgotPasswordDialog extends StatelessWidget {
  const _ForgotPasswordDialog({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Reset Password',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter your email address and we\'ll send you a reset link.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          _AppTextField(
            controller: controller,
            hint: 'Email address',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(controller.text.trim()),
          child: const Text('Send Reset Link'),
        ),
      ],
    );
  }
}

// ── Reusable sub-widgets ───────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  const _AppTextField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: Icon(prefixIcon, color: AppColors.accent, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffixIcon,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        child: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? const Color(0xFFC62828) : AppColors.primary;
    final bg = isError ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5EE);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: color,
          fontWeight: FontWeight.w500,
        ),
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
      ..cubicTo(
          14.13 * s, 4.18 * s, 15.25 * s, 4.62 * s, 16.13 * s, 5.37 * s)
      ..lineTo(18.59 * s, 2.91 * s)
      ..cubicTo(
          16.98 * s, 1.37 * s, 14.62 * s, 0.36 * s, 12 * s, 0.36 * s)
      ..cubicTo(
          7.99 * s, 0.36 * s, 4.6 * s, 2.75 * s, 3.01 * s, 6.17 * s)
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
          15.18 * s, 13.12 * s, 14.48 * s, 14.19 * s, 13.45 * s, 14.93 * s)
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
      ..cubicTo(
          12.62 * s, 15.48 * s, 11.38 * s, 15.82 * s, 10 * s, 15.82 * s)
      ..cubicTo(8.1 * s, 15.82 * s, 6.58 * s, 13.92 * s, 5.95 * s, 11.53 * s)
      ..lineTo(3.01 * s, 13.83 * s)
      ..cubicTo(4.6 * s, 17.25 * s, 7.99 * s, 19.64 * s, 10 * s, 19.64 * s)
      ..close();
    canvas.drawPath(path4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FacebookIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: Color(0xFF1877F2),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'f',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}
