import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:everroute/features/staff/staff_cubit.dart';
import 'package:everroute/features/staff/staff_state.dart';
import 'package:everroute/features/session/staff_auth.dart';
import 'package:everroute/core/network/api_client.dart';
import 'package:everroute/core/theme/app_theme.dart';
import 'package:everroute/ui/screens/staff/widgets/staff_card.dart';
import 'package:everroute/ui/widgets/app_buttons.dart';
import 'package:everroute/ui/widgets/everroute_snack_bar.dart';
import 'package:everroute/services/staff_services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  bool _depsReady = false;
  String? _lastToken;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = staffBearerToken();
    if (!_depsReady) {
      _depsReady = true;
      _lastToken = token;
      _load();
      return;
    }
    if (token != _lastToken) {
      _lastToken = token;
      _load();
    }
  }

  Future<void> _load() async {
    final token = staffBearerToken();
    if (token == null) {
      context.read<StaffCubit>().clear();
      return;
    }
    await context.read<StaffCubit>().load(bearerToken: token);
  }

  Future<void> _refresh() => _load();

  Future<void> _openAddSheet() async {
    await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddStaffSheet(
        onCreate: (payload) async {
          final token = staffBearerToken();
          if (token == null) return;
          await context.read<StaffCubit>().createStaff(
            payload: payload,
            bearerToken: token,
          );
        },
      ),
    );
    if (!mounted) return;
  }

  Future<void> _openInviteSheet() async {
    final invited = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InviteStaffSheet(
        onInvite: (email) async {
          final token = staffBearerToken();
          if (token == null) return;
          await context.read<StaffCubit>().inviteByEmail(
            email: email,
            bearerToken: token,
          );
        },
      ),
    );
    if (invited == true && mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final token = staffBearerToken();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<StaffCubit, StaffState>(
          builder: (context, state) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header card ──────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
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
                    const SizedBox(width: 40),
                    Expanded(
                      child: Text(
                        'Staff',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    // Invite button
                    GestureDetector(
                      onTap: token == null ? null : _openInviteSheet,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.mail_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Add button
                    GestureDetector(
                      onTap: token == null ? null : _openAddSheet,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person_add_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ── List body ────────────────────────────────────────────────
              Expanded(
                child: token == null
                    ? _MessageBody(message: 'Please sign in to load staff.')
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        color: AppColors.primary,
                        child: state.busy
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              )
                            : state.error != null
                            ? _ErrorBody(error: state.error!, onRetry: _refresh)
                            : state.items.isEmpty
                            ? _EmptyBody()
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  24,
                                ),
                                itemCount: state.items.length,
                                itemBuilder: (context, i) {
                                  final m =
                                      state.items[i] as Map<String, dynamic>;
                                  final id = m['id']?.toString() ?? '';
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: StaffCard(
                                      data: m,
                                      onTap: id.isEmpty
                                          ? null
                                          : () async {
                                              final staffCubit = context
                                                  .read<StaffCubit>();
                                              final result = await context
                                                  .push<Map<String, dynamic>>(
                                                    '/staff/$id',
                                                    extra: m,
                                                  );
                                              if (result == null || !mounted) {
                                                return;
                                              }
                                              if (result['deleted'] == true) {
                                                final token =
                                                    staffBearerToken();
                                                if (token != null) {
                                                  await staffCubit.refresh(
                                                    bearerToken: token,
                                                  );
                                                }
                                                return;
                                              }
                                              final hasFields =
                                                  result['name'] != null &&
                                                  result['phone'] != null;
                                              if (!hasFields) {
                                                await _refresh();
                                                return;
                                              }
                                              staffCubit.upsertFromDetail(
                                                result,
                                              );
                                            },
                                    ),
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add Staff bottom sheet ─────────────────────────────────────────────────────

class _AddStaffSheet extends StatefulWidget {
  const _AddStaffSheet({required this.onCreate});

  final Future<void> Function(Map<String, dynamic> payload) onCreate;

  @override
  State<_AddStaffSheet> createState() => _AddStaffSheetState();
}

class _AddStaffSheetState extends State<_AddStaffSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  String _role = 'user';
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final token = staffBearerToken();
    if (token == null) return;
    setState(() => _submitting = true);
    try {
      final payload = <String, dynamic>{
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'role': _role,
      };
      final e = _email.text.trim();
      if (e.isNotEmpty) payload['email'] = e;
      await widget.onCreate(payload);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      EverrouteSnackBar.success(context, 'Staff member created');
    } on ApiException catch (e) {
      if (!mounted) return;
      EverrouteSnackBar.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      EverrouteSnackBar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 24, 20, 20 + bottom),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Staff Member',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              _SheetField(
                label: 'Name',
                controller: _name,
                hint: 'eg. John Smith',
                icon: Icons.person_outline_rounded,
                required: true,
              ),
              const SizedBox(height: 14),
              _SheetField(
                label: 'Phone',
                controller: _phone,
                hint: '555-1234',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                required: true,
              ),
              const SizedBox(height: 14),
              _SheetField(
                label: 'Email',
                controller: _email,
                hint: 'eg. john@email.com',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              // Role dropdown
              _RoleDropdown(
                value: _role,
                enabled: !_submitting,
                onChanged: (v) => setState(() => _role = v ?? 'user'),
              ),
              const SizedBox(height: 24),
              AppPrimaryButton(
                label: 'Create',
                busy: _submitting,
                onPressed: _submit,
              ),
              const SizedBox(height: 10),
              AppAccentButton(
                label: 'Cancel',
                onPressed: _submitting
                    ? null
                    : () => Navigator.of(context).pop(null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Invite Staff bottom sheet ──────────────────────────────────────────────────

class _InviteStaffSheet extends StatefulWidget {
  const _InviteStaffSheet({required this.onInvite});

  final Future<void> Function(String email) onInvite;

  @override
  State<_InviteStaffSheet> createState() => _InviteStaffSheetState();
}

class _InviteStaffSheetState extends State<_InviteStaffSheet> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final token = staffBearerToken();
    if (token == null) return;
    setState(() => _submitting = true);
    try {
      await widget.onInvite(_email.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop(true);
      EverrouteSnackBar.success(
        context,
        'Invite sent. The team member should check their email inbox.',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      final msg = e.statusCode == 403
          ? 'Forbidden: admin role required to invite.'
          : e.message;
      EverrouteSnackBar.error(context, msg);
    } catch (e) {
      if (!mounted) return;
      EverrouteSnackBar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 24, 20, 20 + bottom),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Invite Staff',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Send an invitation email to a team member.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              _SheetField(
                label: 'Email',
                controller: _email,
                hint: 'eg. john@email.com',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                required: true,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!RegExp(
                    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                  ).hasMatch(v.trim())) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              AppPrimaryButton(
                label: 'Send Invite',
                busy: _submitting,
                onPressed: _submit,
              ),
              const SizedBox(height: 10),
              AppAccentButton(
                label: 'Cancel',
                onPressed: _submitting
                    ? null
                    : () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared sheet sub-widgets ───────────────────────────────────────────────────

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.required = false,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool required;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(fontSize: 14),
          validator:
              validator ??
              (required
                  ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
                  : null),
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

class _RoleDropdown extends StatelessWidget {
  const _RoleDropdown({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String value;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Role',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: const Icon(
                Icons.work_outline_rounded,
                color: AppColors.accent,
                size: 18,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
          ),
          items: StaffServices.roles
              .map(
                (r) => DropdownMenuItem<String>(
                  value: r,
                  child: Text(
                    r[0].toUpperCase() + r.substring(1),
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),
              )
              .toList(),
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}

// ── Empty / Error / Message bodies ────────────────────────────────────────────

class _EmptyBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline, size: 56, color: AppColors.border),
          const SizedBox(height: 12),
          Text(
            'No staff yet',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message =
        error is ApiException && (error as ApiException).statusCode == 403
        ? 'Admin role required to manage staff.'
        : error.toString();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.statusCancelledBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.statusCancelledFg,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageBody extends StatelessWidget {
  const _MessageBody({required this.message});

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
