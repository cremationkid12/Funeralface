import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:everroute/features/assignments/assignments_cubit.dart';
import 'package:everroute/features/assignments/assignments_state.dart';
import 'package:everroute/features/dashboard/dashboard_cubit.dart';
import 'package:everroute/features/staff/staff_cubit.dart';
import 'package:everroute/app/app_repositories.dart';
import 'package:everroute/features/session/staff_auth.dart';
import 'package:everroute/core/network/api_client.dart';
import 'package:everroute/core/theme/app_theme.dart';
import 'package:everroute/core/billing_family_share_guard.dart';
import 'package:everroute/core/write_access_guard.dart';
import 'package:everroute/core/env.dart';
import 'package:everroute/core/family_share_token.dart';
import 'package:everroute/ui/screens/assignments/widgets/assignment_card.dart';
import 'package:everroute/core/assignment_eta.dart';
import 'package:everroute/ui/screens/assignments/widgets/assignment_eta_to_arrival_field.dart';
import 'package:everroute/ui/screens/assignments/widgets/assignment_family_link_section.dart';
import 'package:everroute/ui/screens/assignments/widgets/share_family_link_sheet.dart';
import 'package:everroute/ui/widgets/app_buttons.dart';
import 'package:everroute/ui/widgets/app_status_chip.dart';
import 'package:everroute/ui/widgets/everroute_snack_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  late final AssignmentsCubit _assignmentsCubit;

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _assignmentsCubit = AssignmentsCubit(
      assignmentsServices: context.read<AppRepositories>().assignments,
    );
    final token = staffBearerToken();
    if (token != null) {
      _assignmentsCubit.load(bearerToken: token);
    }
  }

  @override
  void dispose() {
    _assignmentsCubit.close();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final token = staffBearerToken();
    if (token == null) return;
    await _assignmentsCubit.refresh(bearerToken: token);
  }

  void _applySearch(String query) {
    _assignmentsCubit.setSearchQuery(query);
  }

  Future<void> _changeStatus({
    required String assignmentId,
    required String status,
  }) async {
    if (!await ensureAdminWriteAccess(context)) return;
    final token = staffBearerToken();
    if (token == null) return;
    try {
      await _assignmentsCubit.updateStatus(
        assignmentId: assignmentId,
        bearerToken: token,
        status: status,
      );
      if (!mounted) return;
      EverrouteSnackBar.success(
        context,
        'Status updated to ${statusLabel(status)}',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'subscription_required' || e.code == 'forbidden') {
        await showWriteAccessApiError(context, e);
        return;
      }
      EverrouteSnackBar.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      EverrouteSnackBar.error(context, e.toString());
    }
  }

  Map<String, dynamic>? _assignmentMap(String assignmentId) {
    for (final it in _assignmentsCubit.state.filteredItems) {
      final m = it as Map<String, dynamic>;
      if (m['id']?.toString() == assignmentId) return m;
    }
    return null;
  }

  Future<void> _copyFamilyLink(String assignmentId) async {
    if (!await ensureSubscriptionAllowsFamilyShare(context)) return;
    final m = _assignmentMap(assignmentId);
    final t = m?['share_token']?.toString().trim();
    if (t == null || t.isEmpty) return;
    await Clipboard.setData(
      ClipboardData(text: AppEnv.familyShareUrlForToken(t)),
    );
    if (!mounted) return;
    EverrouteSnackBar.success(context, 'Link copied');
  }

  Future<String?> _issueShareToken(String assignmentId) async {
    if (!await ensureAdminWriteAccess(context)) return null;
    if (!await ensureSubscriptionAllowsFamilyShare(context)) return null;
    final token = staffBearerToken();
    if (token == null) return null;
    final newToken = generateFamilyShareToken();
    try {
      final body = await _assignmentsCubit.updateAssignment(
        assignmentId: assignmentId,
        bearerToken: token,
        payload: {'share_token': newToken},
      );
      return body['share_token']?.toString().trim() ?? newToken;
    } on ApiException catch (e) {
      if (!mounted) return null;
      EverrouteSnackBar.error(context, e.message);
    } catch (e) {
      if (!mounted) return null;
      EverrouteSnackBar.error(context, e.toString());
    }
    return null;
  }

  Future<void> _openShareFamilyLinkSheet(
    String assignmentId,
    String shareToken,
  ) async {
    if (!await ensureSubscriptionAllowsFamilyShare(context)) return;
    final token = staffBearerToken();
    if (token == null) return;
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareFamilyLinkSheet(
        familyLink: AppEnv.familyShareUrlForToken(shareToken),
        onShare: (email) async {
          await context
              .read<AppRepositories>()
              .assignments
              .shareFamilyLinkByEmail(
                assignmentId: assignmentId,
                email: email,
                bearerToken: token,
              );
        },
      ),
    );
    if (sent == true && mounted) {
      EverrouteSnackBar.success(context, 'Family link sent by email.');
    }
  }

  Future<void> _openShareFamilyLinkFromCard(String assignmentId) async {
    if (!await ensureSubscriptionAllowsFamilyShare(context)) return;
    final m = _assignmentMap(assignmentId);
    final t = m?['share_token']?.toString().trim();
    if (t == null || t.isEmpty) return;
    await _openShareFamilyLinkSheet(assignmentId, t);
  }

  Future<void> _createAndShareFamilyLink(String assignmentId) async {
    final t = await _issueShareToken(assignmentId);
    if (!mounted || t == null || t.isEmpty) return;
    await _openShareFamilyLinkSheet(assignmentId, t);
  }

  Widget? _familyLinkSection(
    BuildContext context,
    AssignmentsState state,
    Map<String, dynamic> m,
    String id,
  ) {
    if (staffBearerToken() == null) return null;
    return AssignmentFamilyLinkSection(
      data: m,
      busy: state.submitting,
      onCopy: () => _copyFamilyLink(id),
      onShare: () => _openShareFamilyLinkFromCard(id),
      onCreate: () => _createAndShareFamilyLink(id),
    );
  }

  Future<void> _openCreateSheet() async {
    if (!await ensureAdminWriteAccess(context)) return;
    List<_AssignableStaffOption> staffOptions = const [];
    try {
      staffOptions = await _loadAssignableStaffOptions();
    } on ApiException catch (e) {
      if (!mounted) return;
      EverrouteSnackBar.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      EverrouteSnackBar.error(context, e.toString());
    }

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateAssignmentSheet(
        staffOptions: staffOptions,
        onCreate: (payload) async {
          final token = staffBearerToken();
          if (token == null) return;
          await _assignmentsCubit.createAssignment(
            payload: payload,
            bearerToken: token,
          );
        },
      ),
    );
    if (!mounted || created != true) return;
    final token = staffBearerToken();
    if (token != null) {
      await context.read<DashboardCubit>().refresh(bearerToken: token);
    }
    if (!mounted) return;
    EverrouteSnackBar.success(context, 'Assignment created');
  }

  Future<List<_AssignableStaffOption>> _loadAssignableStaffOptions() async {
    final staffCubit = context.read<StaffCubit>();
    var items = staffCubit.state.items;
    if (items.isEmpty) {
      final token = staffBearerToken();
      if (token == null) return const [];
      await staffCubit.load(bearerToken: token);
      items = staffCubit.state.items;
    }
    return items
        .whereType<Map<String, dynamic>>()
        .where((item) => item['active'] != false)
        .map((item) {
          final id = item['id']?.toString().trim() ?? '';
          if (id.isEmpty) return null;
          final name = item['name']?.toString().trim() ?? '';
          final email = item['email']?.toString().trim() ?? '';
          final label = name.isNotEmpty
              ? name
              : (email.isNotEmpty ? email : 'Staff $id');
          return _AssignableStaffOption(id: id, label: label);
        })
        .whereType<_AssignableStaffOption>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final token = staffBearerToken();

    return BlocProvider.value(
      value: _assignmentsCubit,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: BlocBuilder<AssignmentsCubit, AssignmentsState>(
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
                      const SizedBox(width: 40), // balance spacing
                      Expanded(
                        child: Text(
                          'Assignments',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      // Orange + button
                      GestureDetector(
                        onTap: token == null || state.submitting
                            ? null
                            : _openCreateSheet,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Search bar ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _applySearch,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search ...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ── List ─────────────────────────────────────────────────────
                Expanded(
                  child: token == null
                      ? Center(
                          child: Text(
                            'Please sign in to load assignments.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          color: AppColors.primary,
                          child: _AssignmentsList(
                            state: state,
                            onRetry: _refresh,
                            onChangeStatus: _changeStatus,
                            onAssignmentUpdated: _refresh,
                            familyLinkSectionBuilder: _familyLinkSection,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Assignment list card ───────────────────────────────────────────────────────

class _AssignmentsList extends StatelessWidget {
  const _AssignmentsList({
    required this.state,
    required this.onRetry,
    required this.onChangeStatus,
    required this.onAssignmentUpdated,
    required this.familyLinkSectionBuilder,
  });

  final AssignmentsState state;
  final Future<void> Function() onRetry;
  final Future<void> Function({
    required String assignmentId,
    required String status,
  })
  onChangeStatus;
  final Future<void> Function() onAssignmentUpdated;

  /// May return null to hide the family link block.
  final Widget? Function(
    BuildContext context,
    AssignmentsState state,
    Map<String, dynamic> m,
    String id,
  )
  familyLinkSectionBuilder;

  @override
  Widget build(BuildContext context) {
    if (state.busy) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (state.error != null) {
      return _ErrorBody(message: state.error!, onRetry: () => onRetry());
    }
    if (state.filteredItems.isEmpty) {
      return _EmptyBody(hasSearch: state.searchQuery.isNotEmpty);
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: state.filteredItems.length,
      itemBuilder: (context, i) {
        final m = state.filteredItems[i] as Map<String, dynamic>;
        final id = m['id']?.toString() ?? '';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AssignmentCard(
            data: m,
            submitting: state.submitting,
            onTap: id.isEmpty
                ? null
                : () async {
                    final changed = await context.push<bool>(
                      '/assignments/$id',
                      extra: m,
                    );
                    if (changed == true) {
                      await onAssignmentUpdated();
                    }
                  },
            onStatusChange: (s) => onChangeStatus(assignmentId: id, status: s),
            familyLinkSection: familyLinkSectionBuilder(context, state, m, id),
          ),
        );
      },
    );
  }
}

// ── Create assignment bottom sheet ─────────────────────────────────────────────

class _CreateAssignmentSheet extends StatefulWidget {
  const _CreateAssignmentSheet({
    required this.onCreate,
    required this.staffOptions,
  });

  final Future<void> Function(Map<String, dynamic> payload) onCreate;
  final List<_AssignableStaffOption> staffOptions;

  @override
  State<_CreateAssignmentSheet> createState() => _CreateAssignmentSheetState();
}

class _CreateAssignmentSheetState extends State<_CreateAssignmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _decedentName = TextEditingController();
  final _pickupAddress = TextEditingController();
  final _contactName = TextEditingController();
  final _contactPhone = TextEditingController();
  final _notes = TextEditingController();
  String? _assignedStaffId;
  TimeOfDay? _etaTime;
  bool _submitting = false;

  @override
  void dispose() {
    _decedentName.dispose();
    _pickupAddress.dispose();
    _contactName.dispose();
    _contactPhone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickEtaTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _etaTime ?? TimeOfDay.now(),
      helpText: 'Select ETA to Arrival',
    );
    if (picked == null || !mounted) return;
    setState(() => _etaTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final token = staffBearerToken();
    if (token == null) return;
    setState(() => _submitting = true);
    try {
      final notes = _notes.text.trim();
      final payload = <String, dynamic>{
        'decedent_name': _decedentName.text.trim(),
        'pickup_address': _pickupAddress.text.trim(),
        'contact_name': _contactName.text.trim(),
        'contact_phone': _contactPhone.text.trim(),
        'status': _assignedStaffId == null ? 'pending' : 'assigned',
      };
      final etaValue = etaTimeToApiValue(_etaTime);
      if (etaValue != null) {
        payload['eta_time'] = etaValue;
      }
      if (_assignedStaffId != null) {
        payload['assigned_staff_id'] = _assignedStaffId;
      }
      if (notes.isNotEmpty) {
        payload['notes'] = notes;
      }
      await widget.onCreate({...payload});
      if (!mounted) return;
      Navigator.of(context).pop(true);
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
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
                'Create assignment',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              _SheetField(
                label: 'Decedent Name',
                controller: _decedentName,
                hint: 'eg. John Smith',
                icon: Icons.person_outline_rounded,
                required: true,
              ),
              const SizedBox(height: 14),
              _SheetField(
                label: 'Pickup Address',
                controller: _pickupAddress,
                hint: 'eg. 123 Oak Street',
                icon: Icons.location_on_outlined,
                required: true,
              ),
              const SizedBox(height: 14),
              _SheetField(
                label: 'Contact Name',
                controller: _contactName,
                hint: 'Jane Smith',
                icon: Icons.person_outline_rounded,
                required: true,
              ),
              const SizedBox(height: 14),
              _SheetField(
                label: 'Contact Phone',
                controller: _contactPhone,
                hint: '555-1234',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                required: true,
              ),
              const SizedBox(height: 14),
              _StaffDropdown(
                value: _assignedStaffId,
                enabled: !_submitting,
                staffOptions: widget.staffOptions,
                onChanged: (value) => setState(() => _assignedStaffId = value),
              ),
              const SizedBox(height: 14),
              AssignmentEtaToArrivalField(
                etaTime: _etaTime,
                enabled: !_submitting,
                onPick: _pickEtaTime,
                onClear: () => setState(() => _etaTime = null),
              ),
              const SizedBox(height: 14),
              // Notes textarea
              Text(
                'NOTES (OPTIONAL)',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notes,
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
                    : () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.required = false,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool required;

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
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null,
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

class _StaffDropdown extends StatelessWidget {
  const _StaffDropdown({
    required this.value,
    required this.enabled,
    required this.staffOptions,
    required this.onChanged,
  });

  final String? value;
  final bool enabled;
  final List<_AssignableStaffOption> staffOptions;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedId = staffOptions.any((item) => item.id == value)
        ? value
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assign Staff (Optional)',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String?>(
          initialValue: selectedId,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: const Icon(
                Icons.person_pin_outlined,
                color: AppColors.accent,
                size: 18,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
          ),
          items: <DropdownMenuItem<String?>>[
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Unassigned'),
            ),
            ...staffOptions.map(
              (staff) => DropdownMenuItem<String?>(
                value: staff.id,
                child: Text(staff.label),
              ),
            ),
          ],
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}

class _AssignableStaffOption {
  const _AssignableStaffOption({required this.id, required this.label});

  final String id;
  final String label;
}

// ── Empty / Error states ───────────────────────────────────────────────────────

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.hasSearch});

  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasSearch ? Icons.search_off_rounded : Icons.assignment_outlined,
            size: 56,
            color: AppColors.border,
          ),
          const SizedBox(height: 12),
          Text(
            hasSearch ? 'No results found' : 'No assignments yet',
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
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
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
