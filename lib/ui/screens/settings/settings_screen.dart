import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:funeralface_mobile/app/app_repositories.dart';
import 'package:funeralface_mobile/features/settings/settings_cubit.dart';
import 'package:funeralface_mobile/features/settings/settings_state.dart';
import 'package:funeralface_mobile/features/session/staff_auth.dart';
import 'package:funeralface_mobile/core/network/api_client.dart';
import 'package:funeralface_mobile/core/theme/app_theme.dart';
import 'package:funeralface_mobile/services/auth_services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

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

  late final SettingsCubit _settingsCubit;
  final ImagePicker _imagePicker = ImagePicker();
  bool _signOutBusy = false;
  bool _scheduledLoad = false;

  @override
  void initState() {
    super.initState();
    _settingsCubit = SettingsCubit(
      settingsServices: context.read<AppRepositories>().settings,
    );
  }

  @override
  void dispose() {
    _settingsCubit.close();
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _logoUrl.dispose();
    _defaultMessage.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduledLoad) return;
    _scheduledLoad = true;
    if (staffBearerToken() == null) {
      _settingsCubit.clear();
      return;
    }
    _load();
  }

  Future<void> _load() async {
    final token = staffBearerToken();
    if (token == null) {
      _settingsCubit.clear();
      return;
    }
    await _settingsCubit.load(bearerToken: token);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final token = staffBearerToken();
    if (token == null) return;
    try {
      await _settingsCubit.save(
        bearerToken: token,
        payload: {
          'funeral_home_name': _name.text.trim(),
          'funeral_home_phone': _phone.text.trim(),
          'funeral_home_address': _address.text.trim(),
          'logo_url': _logoUrl.text.trim().isEmpty
              ? null
              : _logoUrl.text.trim(),
          'default_message': _defaultMessage.text.trim().isEmpty
              ? null
              : _defaultMessage.text.trim(),
        },
      );
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

  Future<void> _pickAndUploadLogo() async {
    final token = staffBearerToken();
    if (token == null) return;
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final logoUrl = await _settingsCubit.uploadLogo(
        bearerToken: token,
        fileBytes: bytes,
        fileName: picked.name,
      );
      _logoUrl.text = logoUrl;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo uploaded successfully')),
      );
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
    }
  }

  void _applySettings(Map<String, dynamic> data) {
    _name.text = data['funeral_home_name']?.toString() ?? '';
    _phone.text = data['funeral_home_phone']?.toString() ?? '';
    _address.text = data['funeral_home_address']?.toString() ?? '';
    _logoUrl.text = data['logo_url']?.toString() ?? '';
    _defaultMessage.text = data['default_message']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final token = staffBearerToken();

    return BlocProvider.value(
      value: _settingsCubit,
      child: BlocListener<SettingsCubit, SettingsState>(
        listenWhen: (previous, current) =>
            current.settings != null && current.settings != previous.settings,
        listener: (context, state) {
          final settings = state.settings;
          if (settings != null) _applySettings(settings);
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, state) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header card ──────────────────────────────────────────────
                  _HeaderCard(
                    onSignOut: token == null ? null : _signOut,
                    signOutBusy: _signOutBusy,
                  ),

                  const SizedBox(height: 10),

                  // ── Body ─────────────────────────────────────────────────────
                  Expanded(
                    child: token == null
                        ? _MessageState(
                            message:
                                'Please sign in to load and edit settings.',
                          )
                        : state.busy
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          )
                        : state.error != null
                        ? _ErrorState(
                            error: state.error!,
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
                            saving: state.saving,
                            logoUploading: state.logoUploading,
                            onSave: _save,
                            onUploadLogo: _pickAndUploadLogo,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({this.onSignOut, this.signOutBusy = false});

  final VoidCallback? onSignOut;
  final bool signOutBusy;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
          if (onSignOut != null)
            GestureDetector(
              onTap: signOutBusy ? null : onSignOut,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: signOutBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                ),
              ),
            )
          else
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
    required this.saving,
    required this.logoUploading,
    required this.onSave,
    required this.onUploadLogo,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController logoUrlController;
  final TextEditingController defaultMessageController;
  final bool saving;
  final bool logoUploading;
  final VoidCallback onSave;
  final VoidCallback onUploadLogo;

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
                _LogoCirclePicker(
                  logoUrlController: logoUrlController,
                  uploading: logoUploading,
                  disabled: saving || logoUploading,
                  onUploadLogo: onUploadLogo,
                ),
                const SizedBox(height: 20),
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
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                // Notes / family message textarea
                _FieldLabel('Family Message (OPTIONAL)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: defaultMessageController,
                  maxLines: 3,
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
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
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

// ── Logo picker ────────────────────────────────────────────────────────────────

class _LogoCirclePicker extends StatelessWidget {
  const _LogoCirclePicker({
    required this.logoUrlController,
    required this.uploading,
    required this.disabled,
    required this.onUploadLogo,
  });
  final TextEditingController logoUrlController;
  final bool uploading;
  final bool disabled;
  final VoidCallback onUploadLogo;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: logoUrlController,
      builder: (context, value, _) {
        final url = value.text.trim();
        final hasLogo = url.isNotEmpty;

        return Center(
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: disabled ? null : onUploadLogo,
                    child: Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                        color: AppColors.background,
                      ),
                      child: ClipOval(
                        child: hasLogo
                            ? Image.network(
                                url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.broken_image_outlined,
                                  size: 28,
                                  color: AppColors.textSecondary,
                                ),
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                    ),
                                  );
                                },
                              )
                            : const Icon(
                                Icons.home_work_outlined,
                                size: 32,
                                color: AppColors.textSecondary,
                              ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: disabled ? null : onUploadLogo,
                        borderRadius: BorderRadius.circular(16),
                        child: Ink(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: uploading
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    hasLogo
                                        ? Icons.edit_rounded
                                        : Icons.upload_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
