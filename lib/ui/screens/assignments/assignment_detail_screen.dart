import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:everroute/app/app_repositories.dart';
import 'package:everroute/features/assignments/assignments_cubit.dart';
import 'package:everroute/features/dashboard/dashboard_cubit.dart';
import 'package:everroute/features/session/staff_auth.dart';
import 'package:everroute/features/staff/staff_cubit.dart';
import 'package:everroute/core/network/api_client.dart';
import 'package:everroute/core/write_access_guard.dart';
import 'package:everroute/services/assignments_services.dart';
import 'package:everroute/core/assignment_eta.dart';
import 'package:everroute/ui/screens/assignments/widgets/assignment_eta_to_arrival_field.dart';
import 'package:everroute/ui/widgets/app_status_chip.dart';
import 'package:everroute/ui/widgets/everroute_snack_bar.dart';

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
  TimeOfDay? _etaTime;

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
    _etaTime = etaTimeFromAssignmentValue(widget.initial['eta_time']);
    _loadAssignableStaff();
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
      final status = body['status']?.toString().trim();
      if (status != null && status.isNotEmpty) {
        _status = status;
      }
      final assignedStaffId = body['assigned_staff_id']?.toString().trim();
      _assignedStaffId = (assignedStaffId != null && assignedStaffId.isNotEmpty)
          ? assignedStaffId
          : null;
      _etaTime = etaTimeFromAssignmentValue(body['eta_time']);
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
        EverrouteSnackBar.error(
          context,
          'Unable to load staff list right now.',
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
      EverrouteSnackBar.error(context, 'Unable to load staff list right now.');
    }
  }

  Future<void> _save() async {
    if (!await ensureAdminWriteAccess(context)) return;
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
          'eta_time': etaTimeToApiValue(_etaTime),
        },
      );
      if (!mounted) return null;
      _applyAssignmentResponse(body);
      _didUpdate = true;
      await context.read<DashboardCubit>().refresh(bearerToken: token);
      EverrouteSnackBar.success(context, 'Assignment saved');
    } on ApiException catch (e) {
      if (!mounted) return null;
      if (e.code == 'subscription_required' || e.code == 'forbidden') {
        await showWriteAccessApiError(context, e);
        return;
      }
      EverrouteSnackBar.error(context, e.message);
    } catch (e) {
      if (!mounted) return null;
      EverrouteSnackBar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _setStatus(String next) {
    setState(() => _status = next);
  }

  @override
  Widget build(BuildContext context) {
    final token = staffBearerToken();

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
                    AssignmentEtaToArrivalField(
                      etaTime: _etaTime,
                      enabled: !_saving,
                      useOutlinedBorder: true,
                      onPick: _pickEtaTime,
                      onClear: () => setState(() => _etaTime = null),
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
