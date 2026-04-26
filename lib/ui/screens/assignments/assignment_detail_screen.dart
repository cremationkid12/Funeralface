import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:funeralface_mobile/app/app_repositories.dart';
import 'package:funeralface_mobile/features/assignments/assignments_cubit.dart';
import 'package:funeralface_mobile/features/session/staff_auth.dart';
import 'package:funeralface_mobile/features/staff/staff_cubit.dart';
import 'package:funeralface_mobile/core/env.dart';
import 'package:funeralface_mobile/core/family_share_token.dart';
import 'package:funeralface_mobile/core/network/api_client.dart';
import 'package:funeralface_mobile/services/assignments_services.dart';
import 'package:funeralface_mobile/ui/widgets/app_status_chip.dart';

class AssignmentDetailScreen extends StatefulWidget {
  const AssignmentDetailScreen({
    super.key,
    required this.assignmentId,
    required this.initial,
  });

  final String assignmentId;
  final Map<String, dynamic> initial;

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  late final AssignmentsCubit _assignmentsCubit;
  late final TextEditingController _decedentName;
  late final TextEditingController _pickupAddress;
  late final TextEditingController _contactName;
  late final TextEditingController _contactPhone;
  late final TextEditingController _notes;

  var _saving = false;
  var _didUpdate = false;
  String _status = '';
  String? _assignedStaffId;
  List<_AssignableStaffOption> _staffOptions = const [];
  var _loadingStaff = false;

  String? _shareToken;
  String? _shareExpiresIso;
  var _shareOneTime = false;

  @override
  void initState() {
    super.initState();
    _assignmentsCubit = AssignmentsCubit(
      assignmentsServices: context.read<AppRepositories>().assignments,
    );
    _decedentName = TextEditingController(
      text: widget.initial['decedent_name']?.toString() ?? '',
    );
    _pickupAddress = TextEditingController(
      text: widget.initial['pickup_address']?.toString() ?? '',
    );
    _contactName = TextEditingController(
      text: widget.initial['contact_name']?.toString() ?? '',
    );
    _contactPhone = TextEditingController(
      text: widget.initial['contact_phone']?.toString() ?? '',
    );
    _notes = TextEditingController(
      text: widget.initial['notes']?.toString() ?? '',
    );
    _status = widget.initial['status']?.toString() ?? 'pending';
    final rawAssignedStaffId = widget.initial['assigned_staff_id']?.toString();
    _assignedStaffId =
        (rawAssignedStaffId != null && rawAssignedStaffId.isNotEmpty)
        ? rawAssignedStaffId
        : null;
    _readShareFromMap(widget.initial);
    _loadAssignableStaff();
  }

  void _readShareFromMap(Map<String, dynamic> map) {
    final t = map['share_token']?.toString().trim();
    _shareToken = (t != null && t.isNotEmpty) ? t : null;
    _shareExpiresIso = map['share_token_expires_at']?.toString();
    _shareOneTime = map['share_token_one_time'] == true;
  }

  @override
  void dispose() {
    _assignmentsCubit.close();
    _decedentName.dispose();
    _pickupAddress.dispose();
    _contactName.dispose();
    _contactPhone.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _applyAssignmentResponse(Map<String, dynamic> body) {
    if (!mounted) return;
    setState(() {
      _readShareFromMap(body);
      final status = body['status']?.toString().trim();
      if (status != null && status.isNotEmpty) {
        _status = status;
      }
      final assignedStaffId = body['assigned_staff_id']?.toString().trim();
      _assignedStaffId = (assignedStaffId != null && assignedStaffId.isNotEmpty)
          ? assignedStaffId
          : null;
    });
  }

  Future<void> _loadAssignableStaff() async {
    final staffCubit = context.read<StaffCubit>();
    var items = staffCubit.state.items;
    final shouldLoad = items.isEmpty;

    if (shouldLoad) {
      final token = staffBearerToken();
      if (token == null) return;
      setState(() => _loadingStaff = true);
      try {
        await staffCubit.load(bearerToken: token);
        items = staffCubit.state.items;
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load staff list right now.')),
        );
      } finally {
        if (mounted) setState(() => _loadingStaff = false);
      }
    }

    try {
      final options = items
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
      if (!mounted) return null;
      setState(() => _staffOptions = options);
    } catch (_) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load staff list right now.')),
      );
    }
  }

  Future<void> _save() async {
    final token = staffBearerToken();
    if (token == null) return;
    setState(() => _saving = true);
    try {
      final statusToSave = _assignedStaffId == null && _status == 'assigned'
          ? 'pending'
          : (_assignedStaffId != null && _status == 'pending'
                ? 'assigned'
                : _status);
      final body = await _assignmentsCubit.updateAssignment(
        assignmentId: widget.assignmentId,
        bearerToken: token,
        payload: {
          'decedent_name': _decedentName.text.trim(),
          'pickup_address': _pickupAddress.text.trim(),
          'contact_name': _contactName.text.trim(),
          'contact_phone': _contactPhone.text.trim(),
          'notes': _notes.text.trim(),
          'status': statusToSave,
          'assigned_staff_id': _assignedStaffId,
        },
      );
      if (!mounted) return null;
      _applyAssignmentResponse(body);
      _didUpdate = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Assignment saved')));
    } on ApiException catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _setStatus(String next) {
    setState(() => _status = next);
  }

  Future<void> _copyFamilyLink() async {
    final t = _shareToken?.trim();
    if (t == null || t.isEmpty) return;
    await Clipboard.setData(
      ClipboardData(text: AppEnv.familyShareUrlForToken(t)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copied')));
  }

  Future<String?> _issueShareToken() async {
    final token = staffBearerToken();
    if (token == null) return null;
    final newToken = generateFamilyShareToken();
    setState(() => _saving = true);
    try {
      final body = await _assignmentsCubit.updateAssignment(
        assignmentId: widget.assignmentId,
        bearerToken: token,
        payload: {'share_token': newToken},
      );
      if (!mounted) return null;
      _applyAssignmentResponse(body);
      final resolvedToken =
          _shareToken ?? body['share_token']?.toString().trim() ?? newToken;
      if (_shareToken == null || _shareToken!.isEmpty) {
        setState(() => _shareToken = resolvedToken);
      }
      _didUpdate = true;
      return resolvedToken;
    } on ApiException catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    return null;
  }

  Future<void> _createAndShareFamilyLink() async {
    final token = await _issueShareToken();
    if (!mounted || token == null || token.isEmpty) return;
    await _openShareFamilyLinkSheet();
  }

  Future<void> _openShareFamilyLinkSheet() async {
    final token = staffBearerToken();
    final shareToken = _shareToken?.trim();
    if (token == null || shareToken == null || shareToken.isEmpty) return;
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareFamilyLinkSheet(
        familyLink: AppEnv.familyShareUrlForToken(shareToken),
        onShare: (email) async {
          await context
              .read<AppRepositories>()
              .assignments
              .shareFamilyLinkByEmail(
                assignmentId: widget.assignmentId,
                email: email,
                bearerToken: token,
              );
        },
      ),
    );
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Family link sent by email.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = staffBearerToken();
    final shareUrl = (_shareToken != null && _shareToken!.isNotEmpty)
        ? AppEnv.familyShareUrlForToken(_shareToken!)
        : null;

    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_didUpdate);
      },
      child: BlocProvider.value(
        value: _assignmentsCubit,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Assignment'),
            actions: [
              TextButton(
                onPressed: token == null || _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
          body: token == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Please sign in to view and edit assignment details.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Status',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        DropdownButton<String>(
                          value: _status,
                          onChanged: _saving
                              ? null
                              : (v) => v == null ? null : _setStatus(v),
                          items: AssignmentsServices.statuses
                              .map(
                                (s) => DropdownMenuItem<String>(
                                  value: s,
                                  child: Text(statusLabel(s)),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Assigned staff (optional)',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (_loadingStaff)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (_) {
                        final selectedId =
                            _staffOptions.any(
                              (staff) => staff.id == _assignedStaffId,
                            )
                            ? _assignedStaffId
                            : null;
                        return DropdownButtonFormField<String?>(
                          initialValue: selectedId,
                          onChanged: _saving || _loadingStaff
                              ? null
                              : (value) =>
                                    setState(() => _assignedStaffId = value),
                          items: <DropdownMenuItem<String?>>[
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Unassigned'),
                            ),
                            ..._staffOptions.map(
                              (staff) => DropdownMenuItem<String?>(
                                value: staff.id,
                                child: Text(staff.label),
                              ),
                            ),
                          ],
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _decedentName,
                      decoration: const InputDecoration(
                        labelText: 'Decedent name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pickupAddress,
                      decoration: const InputDecoration(
                        labelText: 'Pickup address',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _contactName,
                      decoration: const InputDecoration(
                        labelText: 'Contact name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _contactPhone,
                      decoration: const InputDecoration(
                        labelText: 'Contact phone',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notes,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Family status link',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Share a link so families can see assignment status without signing in. '
                      'Only send links through your usual secure channels.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    if (shareUrl != null) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SelectableText(
                              shareUrl,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Copy link',
                            onPressed: _saving ? null : _copyFamilyLink,
                            icon: const Icon(Icons.copy, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: _saving ? null : _openShareFamilyLinkSheet,
                        icon: const Icon(Icons.send),
                        label: const Text('Share Link'),
                      ),
                      if (_shareExpiresIso != null &&
                          _shareExpiresIso!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Expires: $_shareExpiresIso',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      if (_shareOneTime)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'One-time: the first successful open consumes this link.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ] else ...[
                      FilledButton.icon(
                        onPressed: _saving ? null : _createAndShareFamilyLink,
                        icon: const Icon(Icons.link),
                        label: const Text('Create & share link'),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _AssignableStaffOption {
  const _AssignableStaffOption({required this.id, required this.label});

  final String id;
  final String label;
}

class _ShareFamilyLinkSheet extends StatefulWidget {
  const _ShareFamilyLinkSheet({
    required this.familyLink,
    required this.onShare,
  });

  final String familyLink;
  final Future<void> Function(String email) onShare;

  @override
  State<_ShareFamilyLinkSheet> createState() => _ShareFamilyLinkSheetState();
}

class _ShareFamilyLinkSheetState extends State<_ShareFamilyLinkSheet> {
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
    setState(() => _submitting = true);
    try {
      await widget.onShare(_email.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop(true);
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
                'Share Family Link',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Send the family status page link by email.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              SelectableText(
                widget.familyLink,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final v = value?.trim() ?? "";
                  if (v.isEmpty) return 'Required';
                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Family email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send Link'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _submitting
                    ? null
                    : () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
