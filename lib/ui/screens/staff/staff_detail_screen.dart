import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:everroute/features/staff/staff_cubit.dart';
import 'package:everroute/features/session/staff_auth.dart';
import 'package:everroute/core/network/api_client.dart';
import 'package:everroute/core/theme/app_theme.dart';
import 'package:everroute/services/staff_services.dart';
import 'package:everroute/ui/widgets/app_buttons.dart';
import 'package:everroute/ui/widgets/everroute_snack_bar.dart';
import 'package:google_fonts/google_fonts.dart';

class StaffDetailScreen extends StatefulWidget {
  const StaffDetailScreen({
    super.key,
    required this.staffId,
    required this.initial,
  });

  final String staffId;
  final Map<String, dynamic> initial;

  @override
  State<StaffDetailScreen> createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends State<StaffDetailScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _bio;
  String _role = 'user';
  late bool _active;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: widget.initial['name']?.toString() ?? '',
    );
    _phone = TextEditingController(
      text: widget.initial['phone']?.toString() ?? '',
    );
    _email = TextEditingController(
      text: widget.initial['email']?.toString() ?? '',
    );
    _bio = TextEditingController(text: widget.initial['bio']?.toString() ?? '');
    final r = widget.initial['role']?.toString();
    _role = r != null && StaffServices.roles.contains(r) ? r : 'user';
    final a = widget.initial['active'];
    _active = a is bool ? a : a?.toString().toLowerCase() != 'false';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final token = staffBearerToken();
    if (token == null) return;
    setState(() => _busy = true);
    try {
      final payload = <String, dynamic>{
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'role': _role,
        'active': _active,
        'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
        'bio': _bio.text.trim().isEmpty ? null : _bio.text.trim(),
      };
      final updated = await context.read<StaffCubit>().updateStaff(
        id: widget.staffId,
        payload: payload,
        bearerToken: token,
      );
      if (!mounted) return;
      EverrouteSnackBar.success(context, 'Staff member saved');
      Navigator.of(context).pop(updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      EverrouteSnackBar.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      EverrouteSnackBar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleActive(bool next) async {
    final token = staffBearerToken();
    if (token == null) return;

    final ok = await _showConfirmModal(
      icon: Icons.power_settings_new_rounded,
      title: next ? 'Activate staff member?' : 'Deactivate staff member?',
      body: 'This change will be recorded in audit logs (admin-only).',
      confirmLabel: next ? 'Activate' : 'Deactivate',
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final Map<String, dynamic> updated;
      if (next) {
        updated = await context.read<StaffCubit>().activateStaff(
          id: widget.staffId,
          bearerToken: token,
        );
      } else {
        updated = await context.read<StaffCubit>().deactivateStaff(
          id: widget.staffId,
          bearerToken: token,
        );
      }
      if (!mounted) return;
      setState(() => _active = next);
      EverrouteSnackBar.success(
        context,
        next ? 'Staff activated' : 'Staff deactivated',
      );
      Navigator.of(context).pop(updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      EverrouteSnackBar.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      EverrouteSnackBar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await _showConfirmModal(
      icon: Icons.delete_outline_rounded,
      title: 'Remove staff member?',
      body: 'This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (ok != true || !mounted) return;
    final token = staffBearerToken();
    if (token == null) return;
    setState(() => _busy = true);
    try {
      await context.read<StaffCubit>().deleteStaff(
        id: widget.staffId,
        bearerToken: token,
      );
      if (!mounted) return;
      Navigator.of(context).pop({'deleted': true, 'id': widget.staffId});
      EverrouteSnackBar.success(context, 'Staff member removed');
    } on ApiException catch (e) {
      if (!mounted) return;
      EverrouteSnackBar.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      EverrouteSnackBar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Shows the branded bottom-sheet confirmation modal. Returns true if confirmed.
  Future<bool?> _showConfirmModal({
    required IconData icon,
    required String title,
    required String body,
    required String confirmLabel,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmModal(
        icon: icon,
        title: title,
        body: body,
        confirmLabel: confirmLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final token = staffBearerToken();
    final name = _name.text.isNotEmpty ? _name.text : '?';
    final initials = name
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header card ───────────────────────────────────────────────
            Container(
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
                  // Back button
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
                  ),
                  Expanded(
                    child: Text(
                      'Staff Member',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  // Save button
                  GestureDetector(
                    onTap: token == null || _busy ? null : _save,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _busy
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable body ───────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                children: [
                  // ── Avatar ──────────────────────────────────────────────
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Fields card ──────────────────────────────────────────
                  _FieldCard(
                    children: [
                      _DetailField(
                        label: 'Name',
                        controller: _name,
                        icon: Icons.person_outline_rounded,
                        enabled: !_busy,
                      ),
                      const SizedBox(height: 14),
                      _DetailField(
                        label: 'Phone',
                        controller: _phone,
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        enabled: !_busy,
                      ),
                      const SizedBox(height: 14),
                      _DetailField(
                        label: 'Email',
                        controller: _email,
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_busy,
                      ),
                      const SizedBox(height: 14),
                      _DetailFieldLabel('Bio'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _bio,
                        enabled: !_busy,
                        maxLines: 3,
                        textInputAction: TextInputAction.newline,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Write a short bio ...',
                          hintStyle: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Role dropdown
                      _DetailFieldLabel('Role'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _role,
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
                        onChanged: _busy
                            ? null
                            : (v) {
                                if (v != null) setState(() => _role = v);
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Active toggle card ───────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
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
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Active',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      value: _active,
                      activeThumbColor: AppColors.primary,
                      onChanged: _busy ? null : _toggleActive,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Remove button ────────────────────────────────────────
                  AppAccentButton(
                    label: 'Remove Staff Member',
                    icon: Icons.delete_outline_rounded,
                    onPressed: _busy ? null : _confirmDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Confirmation modal (bottom sheet) ─────────────────────────────────────────

class _ConfirmModal extends StatelessWidget {
  const _ConfirmModal({
    required this.icon,
    required this.title,
    required this.body,
    required this.confirmLabel,
  });

  final IconData icon;
  final String title;
  final String body;
  final String confirmLabel;

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
          // Ripple icon
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
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
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            body,
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
              child: Text(confirmLabel),
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

// ── Detail field helpers ───────────────────────────────────────────────────────

class _FieldCard extends StatelessWidget {
  const _FieldCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: children,
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailFieldLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: enabled,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
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

class _DetailFieldLabel extends StatelessWidget {
  const _DetailFieldLabel(this.label);

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
