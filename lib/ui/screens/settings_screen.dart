import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:funeralface_mobile/app/app_repositories.dart';
import 'package:funeralface_mobile/features/session/staff_auth.dart';
import 'package:funeralface_mobile/core/network/api_client.dart';
import 'package:funeralface_mobile/core/theme/app_theme.dart';
import 'package:funeralface_mobile/services/auth_services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _logoUrl = TextEditingController();
  final _defaultMessage = TextEditingController();

  bool _loading = true;
  String? _error;
  bool _saving = false;
  bool _signOutBusy = false;
  bool _scheduledLoad = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _logoUrl.dispose();
    _defaultMessage.dispose();
    super.dispose();
  }

  String? _validateHttpUrl(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    final u = Uri.tryParse(t);
    if (u == null ||
        !u.hasScheme ||
        (u.scheme != 'https' && u.scheme != 'http')) {
      return 'Enter a valid http(s) URL';
    }
    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduledLoad) return;
    _scheduledLoad = true;
    if (staffBearerToken() == null) {
      setState(() => _loading = false);
      return;
    }
    _load();
  }

  Future<void> _load() async {
    final token = staffBearerToken();
    if (token == null) {
      setState(() {
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await context.read<AppRepositories>().settings.getSettings(
        bearerToken: token,
      );
      if (!mounted) return;
      setState(() {
        _name.text = data['funeral_home_name']?.toString() ?? '';
        _phone.text = data['funeral_home_phone']?.toString() ?? '';
        _address.text = data['funeral_home_address']?.toString() ?? '';
        _logoUrl.text = data['logo_url']?.toString() ?? '';
        _defaultMessage.text = data['default_message']?.toString() ?? '';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final token = staffBearerToken();
    if (token == null) return;
    setState(() => _saving = true);
    try {
      await context.read<AppRepositories>().settings.updateSettings({
        'funeral_home_name': _name.text.trim(),
        'funeral_home_phone': _phone.text.trim(),
        'funeral_home_address': _address.text.trim(),
        'logo_url': _logoUrl.text.trim().isEmpty ? null : _logoUrl.text.trim(),
        'default_message': _defaultMessage.text.trim().isEmpty
            ? null
            : _defaultMessage.text.trim(),
      }, bearerToken: token);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings saved')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SignOutModal(),
    );
    if (ok != true || !mounted) return;
    setState(() => _signOutBusy = true);
    try {
      await AuthServices(apiClient: context.read<ApiClient>()).logout();
      if (!mounted) return;
      context.go('/auth');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _signOutBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = staffBearerToken();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header card ──────────────────────────────────────────────
            _HeaderCard(),

            const SizedBox(height: 10),

            // ── Body ─────────────────────────────────────────────────────
            Expanded(
              child: token == null
                  ? _MessageState(
                      message: 'Please sign in to load and edit settings.',
                    )
                  : _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _error != null
                  ? _ErrorState(
                      error: _error!,
                      onRetry: _load,
                      onSignOut: _signOut,
                      signOutBusy: _signOutBusy,
                    )
                  : _FormBody(
                      formKey: _formKey,
                      nameController: _name,
                      phoneController: _phone,
                      addressController: _address,
                      logoUrlController: _logoUrl,
                      defaultMessageController: _defaultMessage,
                      validateUrl: _validateHttpUrl,
                      saving: _saving,
                      signOutBusy: _signOutBusy,
                      onSave: _save,
                      onSignOut: _signOut,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back arrow (only shown when screen was pushed, not from tab)
          if (Navigator.of(context).canPop())
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            )
          else
            const SizedBox(width: 40),
          Expanded(
            child: Text(
              'Settings',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

// ── Form body ─────────────────────────────────────────────────────────────────

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.logoUrlController,
    required this.defaultMessageController,
    required this.validateUrl,
    required this.saving,
    required this.signOutBusy,
    required this.onSave,
    this.onSignOut,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController logoUrlController;
  final TextEditingController defaultMessageController;
  final FormFieldValidator<String> validateUrl;
  final bool saving;
  final bool signOutBusy;
  final VoidCallback onSave;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          // ── Fields card ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SettingsField(
                  label: 'Funeral Family Home Name',
                  controller: nameController,
                  hint: "eg. Emma's House",
                  icon: Icons.home_work_outlined,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _SettingsField(
                  label: 'Phone',
                  controller: phoneController,
                  hint: '555-1234',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _SettingsField(
                  label: 'Address',
                  controller: addressController,
                  hint: 'eg. 123 Oak Street',
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _SettingsField(
                  label: 'Logo URL',
                  controller: logoUrlController,
                  hint: 'eg. abc.com/logo',
                  icon: Icons.link_rounded,
                  keyboardType: TextInputType.url,
                  validator: validateUrl,
                ),
                // Logo preview
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: logoUrlController,
                  builder: (context, value, _) {
                    final url = value.text.trim();
                    if (url.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _LogoPreview(url: url),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Notes / family message textarea
                _FieldLabel('Family Message (OPTIONAL)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: defaultMessageController,
                  maxLines: 4,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Write here ...',
                    hintStyle: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Save button ────────────────────────────────────────────────
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: saving ? null : onSave,
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ),

          // ── Sign out ───────────────────────────────────────────────────
          if (onSignOut != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: (saving || signOutBusy) ? null : onSignOut,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusCancelledFg,
                  side: BorderSide(
                    color: AppColors.statusCancelledFg.withValues(alpha: 0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: signOutBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign out'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Field widgets ──────────────────────────────────────────────────────────────

class _SettingsField extends StatelessWidget {
  const _SettingsField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 14),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(icon, color: AppColors.accent, size: 18),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
          ),
        ),
      ],
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
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }
}

// ── Logo preview ───────────────────────────────────────────────────────────────

class _LogoPreview extends StatelessWidget {
  const _LogoPreview({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Logo preview',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              height: 96,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Row(
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.statusCancelledFg,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Could not load image',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const SizedBox(
                  height: 96,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sign out confirmation modal ────────────────────────────────────────────────

class _SignOutModal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon with ripple rings
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.accentSurface,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Sign out?', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'You will need to sign in again to use staff features.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sign out'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error / Message states ─────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.error,
    required this.onRetry,
    this.onSignOut,
    required this.signOutBusy,
  });

  final String error;
  final VoidCallback onRetry;
  final VoidCallback? onSignOut;
  final bool signOutBusy;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.statusCancelledBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                error,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.statusCancelledFg,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
              if (onSignOut != null) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: signOutBusy ? null : onSignOut,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusCancelledFg,
                    side: BorderSide(
                      color: AppColors.statusCancelledFg.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Sign out'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
