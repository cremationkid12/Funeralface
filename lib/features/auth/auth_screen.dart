import 'package:flutter/material.dart';
import 'package:funeralface_mobile/core/env.dart';
import 'package:funeralface_mobile/features/auth/supabase_auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _registerEmail = TextEditingController();
  final _registerPassword = TextEditingController();
  final _registerConfirm = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _info;

  SupabaseAuthService get _auth => SupabaseAuthService(Supabase.instance.client);

  @override
  void dispose() {
    _tabs.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    _registerEmail.dispose();
    _registerPassword.dispose();
    _registerConfirm.dispose();
    super.dispose();
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

  Future<void> _doRegister() async {
    if (_registerPassword.text != _registerConfirm.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await _auth.register(
        email: _registerEmail.text.trim(),
        password: _registerPassword.text,
      );
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

  Future<void> _openRecoverDialog() async {
    final emailController = TextEditingController(text: _loginEmail.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset password'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(emailController.text.trim()),
            child: const Text('Send'),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    if (!AppEnv.hasSupabaseAuthConfig) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sign in')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Supabase auth is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Login'),
            Tab(text: 'Register'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          if (_info != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_info!, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            ),
          SizedBox(
            height: 320,
            child: TabBarView(
              controller: _tabs,
              children: [
                _AuthForm(
                  emailController: _loginEmail,
                  passwordController: _loginPassword,
                  busy: _busy,
                  submitLabel: 'Login',
                  onSubmit: _doLogin,
                  includeConfirm: false,
                  onForgotPassword: _openRecoverDialog,
                ),
                _AuthForm(
                  emailController: _registerEmail,
                  passwordController: _registerPassword,
                  confirmController: _registerConfirm,
                  busy: _busy,
                  submitLabel: 'Register',
                  onSubmit: _doRegister,
                  includeConfirm: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthForm extends StatelessWidget {
  const _AuthForm({
    required this.emailController,
    required this.passwordController,
    this.confirmController,
    required this.busy,
    required this.submitLabel,
    required this.onSubmit,
    required this.includeConfirm,
    this.onForgotPassword,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController? confirmController;
  final bool busy;
  final String submitLabel;
  final VoidCallback onSubmit;
  final bool includeConfirm;
  final VoidCallback? onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: passwordController,
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
        if (includeConfirm) ...[
          const SizedBox(height: 8),
          TextField(
            controller: confirmController,
            decoration: const InputDecoration(labelText: 'Confirm password'),
            obscureText: true,
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: busy ? null : onSubmit,
          child: busy ? const Text('Please wait...') : Text(submitLabel),
        ),
        if (!includeConfirm) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: busy ? null : onForgotPassword,
            child: const Text('Forgot password?'),
          ),
        ],
      ],
    );
  }
}
