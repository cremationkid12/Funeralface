import 'package:flutter/material.dart';
import 'package:funeralface_mobile/app/app_repositories.dart';
import 'package:funeralface_mobile/app/session/staff_auth.dart';
import 'package:funeralface_mobile/core/network/api_client.dart';
import 'package:funeralface_mobile/core/theme/app_theme.dart';
import 'package:funeralface_mobile/core/widgets/app_status_chip.dart';
import 'package:funeralface_mobile/features/assignments/assignments_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  Future<List<dynamic>>? _future;
  List<dynamic> _allItems = [];
  List<dynamic> _filtered = [];
  String _searchQuery = '';
  bool _depsReady = false;
  bool _submitting = false;

  // Tracks which card indices are expanded
  final Set<String> _expanded = {};

  final _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_depsReady) {
      _depsReady = true;
      _future = _load();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _load() async {
    final result = await context
        .read<AppRepositories>()
        .assignments
        .listAssignments(bearerToken: staffBearerToken());
    setState(() {
      _allItems = result;
      _applySearch(_searchQuery);
    });
    return result;
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  void _applySearch(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      _searchQuery = query;
      if (q.isEmpty) {
        _filtered = List.of(_allItems);
      } else {
        _filtered = _allItems.where((m) {
          final map = m as Map<String, dynamic>;
          final name = (map['decedent_name'] ?? '').toString().toLowerCase();
          final addr = (map['pickup_address'] ?? '').toString().toLowerCase();
          final status = (map['status'] ?? '').toString().toLowerCase();
          return name.contains(q) || addr.contains(q) || status.contains(q);
        }).toList();
      }
    });
  }

  Future<void> _changeStatus({
    required String assignmentId,
    required String status,
  }) async {
    final token = staffBearerToken();
    if (token == null) return;
    setState(() => _submitting = true);
    try {
      await context.read<AppRepositories>().assignments.updateAssignment(
            assignmentId: assignmentId,
            payload: {'status': status},
            bearerToken: token,
          );
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Status updated to ${statusLabel(status)}')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openCreateSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateAssignmentSheet(
        repositories: context.read<AppRepositories>(),
      ),
    );
    if (created == true) await _refresh();
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
                    onTap: token == null || _submitting
                        ? null
                        : _openCreateSheet,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 22),
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
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textSecondary, size: 20),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
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
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
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
                      child: FutureBuilder<List<dynamic>>(
                        future: _future,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary),
                            );
                          }
                          if (snapshot.hasError) {
                            return _ErrorBody(
                              message: snapshot.error.toString(),
                              onRetry: _refresh,
                            );
                          }
                          if (_filtered.isEmpty) {
                            return _EmptyBody(
                              hasSearch: _searchQuery.isNotEmpty,
                            );
                          }
                          return ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: _filtered.length,
                            itemBuilder: (context, i) {
                              final m =
                                  _filtered[i] as Map<String, dynamic>;
                              final id = m['id']?.toString() ?? '';
                              final isExpanded = _expanded.contains(id);
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 10),
                                child: _AssignmentCard(
                                  data: m,
                                  isExpanded: isExpanded,
                                  submitting: _submitting,
                                  onToggle: () => setState(() {
                                    if (isExpanded) {
                                      _expanded.remove(id);
                                    } else {
                                      _expanded.add(id);
                                    }
                                  }),
                                  onTap: id.isEmpty
                                      ? null
                                      : () => context.push(
                                            '/assignments/$id',
                                            extra: m,
                                          ),
                                  onStatusChange: (s) => _changeStatus(
                                      assignmentId: id, status: s),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Assignment accordion card ──────────────────────────────────────────────────

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.data,
    required this.isExpanded,
    required this.submitting,
    required this.onToggle,
    required this.onStatusChange,
    this.onTap,
  });

  final Map<String, dynamic> data;
  final bool isExpanded;
  final bool submitting;
  final VoidCallback onToggle;
  final ValueChanged<String> onStatusChange;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final name = data['decedent_name']?.toString() ?? '—';
    final address = data['pickup_address']?.toString() ?? '';
    final contactName = data['contact_name']?.toString() ?? '';
    final contactPhone = data['contact_phone']?.toString() ?? '';
    final status = data['status']?.toString() ?? '';
    final initials = name.trim().isNotEmpty
        ? name
            .trim()
            .split(' ')
            .map((w) => w.isNotEmpty ? w[0] : '')
            .take(2)
            .join()
        : '?';

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            // ── Summary row ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initials.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + address
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (address.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  size: 13, color: AppColors.accent),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  address,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Expand toggle
                  GestureDetector(
                    onTap: onToggle,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: AnimatedRotation(
                        turns: isExpanded ? 0 : 0.5,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.keyboard_arrow_up_rounded,
                            color: AppColors.accent, size: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (isExpanded) ...[
              // ── Contact row ──────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.statusEnRouteBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color:
                            AppColors.statusEnRouteFg.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.phone_outlined,
                          size: 14, color: AppColors.statusEnRouteFg),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Contact',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      [
                        if (contactName.isNotEmpty) contactName,
                        if (contactPhone.isNotEmpty) contactPhone,
                      ].join(' '),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Status chip row ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: AssignmentsRepository.statuses.map((s) {
                    final isCurrent = s == status;
                    return GestureDetector(
                      onTap: submitting || isCurrent
                          ? null
                          : () => onStatusChange(s),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AppStatusChip(status: s),
                          if (isCurrent)
                            Positioned(
                              top: -4,
                              left: -4,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check,
                                    color: Colors.white, size: 10),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ] else ...[
              // ── Collapsed contact hint ────────────────────────────────────
              if (contactName.isNotEmpty || contactPhone.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.statusEnRouteBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_outlined,
                          size: 14, color: AppColors.statusEnRouteFg),
                      const SizedBox(width: 8),
                      Text(
                        'Contact',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        [
                          if (contactName.isNotEmpty) contactName,
                          if (contactPhone.isNotEmpty) contactPhone,
                        ].join(' '),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Create assignment bottom sheet ─────────────────────────────────────────────

class _CreateAssignmentSheet extends StatefulWidget {
  const _CreateAssignmentSheet({required this.repositories});

  final AppRepositories repositories;

  @override
  State<_CreateAssignmentSheet> createState() =>
      _CreateAssignmentSheetState();
}

class _CreateAssignmentSheetState extends State<_CreateAssignmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _decedentName = TextEditingController();
  final _pickupAddress = TextEditingController();
  final _contactName = TextEditingController();
  final _contactPhone = TextEditingController();
  final _eta = TextEditingController();
  final _notes = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _decedentName.dispose();
    _pickupAddress.dispose();
    _contactName.dispose();
    _contactPhone.dispose();
    _eta.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final token = staffBearerToken();
    if (token == null) return;
    setState(() => _submitting = true);
    try {
      await widget.repositories.assignments.createAssignment(
        bearerToken: token,
        payload: {
          'decedent_name': _decedentName.text.trim(),
          'pickup_address': _pickupAddress.text.trim(),
          'contact_name': _contactName.text.trim(),
          'contact_phone': _contactPhone.text.trim(),
          if (_eta.text.trim().isNotEmpty) 'notes': _eta.text.trim(),
          if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
        },
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment created')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
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
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
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
              _SheetField(
                label: 'ETA to Removal',
                controller: _eta,
                hint: '10:30 PM',
                icon: Icons.schedule_outlined,
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
              const SizedBox(height: 24),
              // Green create button
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Create'),
                ),
              ),
              const SizedBox(height: 10),
              // Orange cancel button
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(false),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                  ),
                  child: const Text('Cancel'),
                ),
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
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
          ),
        ),
      ],
    );
  }
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
            hasSearch
                ? Icons.search_off_rounded
                : Icons.assignment_outlined,
            size: 56,
            color: AppColors.border,
          ),
          const SizedBox(height: 12),
          Text(
            hasSearch ? 'No results found' : 'No assignments yet',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppColors.textSecondary),
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
                    fontSize: 13, color: AppColors.statusCancelledFg),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
