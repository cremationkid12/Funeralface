import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:everroute/app/app_repositories.dart';
import 'package:everroute/features/settings/settings_cubit.dart';
import 'package:everroute/features/settings/settings_state.dart';
import 'package:everroute/features/session/staff_auth.dart';
import 'package:everroute/features/session/auth_session.dart';
import 'package:everroute/core/network/api_client.dart';
import 'package:everroute/core/theme/app_theme.dart';
import 'package:everroute/services/auth_services.dart';
import 'package:everroute/services/staff_services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:everroute/ui/screens/settings/widgets/funeral_home_tab.dart';
import 'package:everroute/ui/screens/settings/widgets/my_profile_tab.dart';
import 'package:everroute/ui/widgets/app_buttons.dart';
import 'package:everroute/ui/widgets/everroute_snack_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _homeFormKey = GlobalKey<FormState>();
  final _profileFormKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _logoUrl = TextEditingController();
  final _defaultMessage = TextEditingController();
  final _myProfileImageUrl = TextEditingController();
  final _myName = TextEditingController();
  final _myPhone = TextEditingController();
  final _myEmail = TextEditingController();
  final _myBio = TextEditingController();

  late final SettingsCubit _settingsCubit;
  late final StaffServices _staffServices;
  final ImagePicker _imagePicker = ImagePicker();
  bool _signOutBusy = false;
  bool _scheduledLoad = false;
  bool _profileBusy = false;
  bool _profileSaving = false;
  bool _profileImageUploading = false;
  String? _profileError;
  String _myRole = 'user';

  @override
  void initState() {
    super.initState();
    _staffServices = context.read<AppRepositories>().staff;
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
    _myProfileImageUrl.dispose();
    _myName.dispose();
    _myPhone.dispose();
    _myEmail.dispose();
    _myBio.dispose();
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
      setState(() {
        _profileBusy = false;
        _profileError = null;
      });
      return;
    }
    await Future.wait([
      _settingsCubit.load(bearerToken: token),
      _loadMyProfile(bearerToken: token),
    ]);
  }

  Future<void> _loadMyProfile({required String bearerToken}) async {
    if (!mounted) return;
    setState(() {
      _profileBusy = true;
      _profileError = null;
    });
    try {
      final profile = await _staffServices.getMyProfile(
        bearerToken: bearerToken,
      );
      if (!mounted) return;
      setState(() {
        _profileBusy = false;
        _profileError = null;
      });
      _applyProfile(profile);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _profileBusy = false;
        _profileError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profileBusy = false;
        _profileError = e.toString();
      });
    }
  }

  Future<void> _saveFuneralHome() async {
    if (!_isAdmin) return;
    if (!(_homeFormKey.currentState?.validate() ?? false)) return;
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
      EverrouteSnackBar.success(context, 'Funeral Home information saved');
    } on ApiException catch (e) {
      if (!mounted) return;
      EverrouteSnackBar.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      EverrouteSnackBar.error(context, e.toString());
    }
  }

  Future<void> _saveMyProfile() async {
    if (!(_profileFormKey.currentState?.validate() ?? false)) return;
    final token = staffBearerToken();
    if (token == null) return;
    setState(() => _profileSaving = true);
    try {
      await _staffServices.updateMyProfile(
        bearerToken: token,
        payload: {
          'name': _myName.text.trim(),
          'phone': _myPhone.text.trim(),
          'email': _myEmail.text.trim().isEmpty ? null : _myEmail.text.trim(),
          'bio': _myBio.text.trim().isEmpty ? null : _myBio.text.trim(),
          'profile_image_url': _myProfileImageUrl.text.trim().isEmpty
              ? null
              : _myProfileImageUrl.text.trim(),
        },
      );
      if (!mounted) return;
      EverrouteSnackBar.success(context, 'Profile saved');
    } on ApiException catch (e) {
      if (!mounted) return;
      EverrouteSnackBar.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      EverrouteSnackBar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _profileSaving = false);
    }
  }

  Future<void> _pickAndUploadProfileImage(ImageSource source) async {
    final token = staffBearerToken();
    if (token == null) return;
    final userId = AuthSession.instance.userId?.trim();
    if (userId == null || userId.isEmpty) return;
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (picked == null) return;
      if (!mounted) return;
      setState(() => _profileImageUploading = true);
      final bytes = await picked.readAsBytes();
      final imageUrl = await _staffServices.uploadMyProfileImage(
        bearerToken: token,
        bytes: bytes,
        fileName: picked.name,
        staffId: userId,
      );
      await _staffServices.updateMyProfile(
        bearerToken: token,
        payload: <String, dynamic>{'profile_image_url': imageUrl},
      );
      _myProfileImageUrl.text = imageUrl;
      if (!mounted) return;
      EverrouteSnackBar.success(context, 'Profile image uploaded and saved');
    } on ApiException catch (e) {
      if (!mounted) return;
      EverrouteSnackBar.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      EverrouteSnackBar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _profileImageUploading = false);
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
      EverrouteSnackBar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _signOutBusy = false);
    }
  }

  Future<void> _pickAndUploadLogo(ImageSource source) async {
    final token = staffBearerToken();
    if (token == null) return;
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
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
      await _settingsCubit.save(
        bearerToken: token,
        payload: <String, dynamic>{'logo_url': logoUrl},
      );

      if (!mounted) return;
      EverrouteSnackBar.success(context, 'Logo uploaded and saved');
    } on ApiException catch (e) {
      if (!mounted) return;
      EverrouteSnackBar.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      EverrouteSnackBar.error(context, e.toString());
    }
  }

  void _applySettings(Map<String, dynamic> data) {
    _name.text = data['funeral_home_name']?.toString() ?? '';
    _phone.text = data['funeral_home_phone']?.toString() ?? '';
    _address.text = data['funeral_home_address']?.toString() ?? '';
    _logoUrl.text = data['logo_url']?.toString() ?? '';
    _defaultMessage.text = data['default_message']?.toString() ?? '';
  }

  void _applyProfile(Map<String, dynamic> data) {
    _myProfileImageUrl.text = data['profile_image_url']?.toString() ?? '';
    _myName.text = data['name']?.toString() ?? '';
    _myPhone.text = data['phone']?.toString() ?? '';
    _myEmail.text = data['email']?.toString() ?? '';
    _myBio.text = data['bio']?.toString() ?? '';
    _myRole = data['role']?.toString().trim().toLowerCase() == 'admin'
        ? 'admin'
        : 'user';
  }

  bool get _isAdmin => _myRole == 'admin';

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
                        : (state.busy || _profileBusy)
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          )
                        : (state.error != null || _profileError != null)
                        ? _ErrorState(
                            error:
                                state.error ??
                                _profileError ??
                                'Unable to load settings.',
                            onRetry: _load,
                            onSignOut: _signOut,
                            signOutBusy: _signOutBusy,
                          )
                        : DefaultTabController(
                            length: 2,
                            child: Column(
                              children: [
                                Container(
                                  margin: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TabBar(
                                    dividerColor: Colors.transparent,
                                    indicatorSize: TabBarIndicatorSize.tab,
                                    labelColor: Colors.white,
                                    unselectedLabelColor:
                                        AppColors.textSecondary,
                                    indicator: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    tabs: const [
                                      Tab(text: 'Funeral Home'),
                                      Tab(text: 'My Profile'),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: TabBarView(
                                    children: [
                                      FuneralHomeTab(
                                        formKey: _homeFormKey,
                                        nameController: _name,
                                        phoneController: _phone,
                                        addressController: _address,
                                        logoUrlController: _logoUrl,
                                        defaultMessageController:
                                            _defaultMessage,
                                        saving: state.saving,
                                        logoUploading: state.logoUploading,
                                        editable: _isAdmin,
                                        onSave: _saveFuneralHome,
                                        onPickLogo: _pickAndUploadLogo,
                                      ),
                                      MyProfileTab(
                                        formKey: _profileFormKey,
                                        imageUrlController: _myProfileImageUrl,
                                        nameController: _myName,
                                        phoneController: _myPhone,
                                        emailController: _myEmail,
                                        bioController: _myBio,
                                        role: _myRole,
                                        saving: _profileSaving,
                                        imageUploading: _profileImageUploading,
                                        onPickImage: _pickAndUploadProfileImage,
                                        onSave: _saveMyProfile,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
          if (onSignOut != null)
            GestureDetector(
              onTap: signOutBusy ? null : onSignOut,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.statusCancelledFg,
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
          AppPrimaryButton(
            label: 'Sign out',
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 10),
          AppAccentButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(false),
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
