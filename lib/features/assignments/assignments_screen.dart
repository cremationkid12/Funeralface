import 'package:flutter/material.dart';
import 'package:funeralface_mobile/app/app_repositories.dart';
import 'package:funeralface_mobile/app/session/staff_auth.dart';
import 'package:funeralface_mobile/core/network/api_client.dart';
import 'package:funeralface_mobile/features/assignments/assignments_repository.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  Future<List<dynamic>>? _future;
  var _depsReady = false;
  var _submitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_depsReady) {
      _depsReady = true;
      _future = _load();
    }
  }

  Future<List<dynamic>> _load() {
    return context.read<AppRepositories>().assignments.listAssignments(
          bearerToken: staffBearerToken(),
        );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _openCreateDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => const _CreateAssignmentDialog(),
    );
    if (created == true) {
      await _refresh();
    }
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
        SnackBar(content: Text('Assignment status updated to $status')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = staffBearerToken();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
        actions: [
          IconButton(
            tooltip: 'Create assignment',
            onPressed: token == null || _submitting ? null : _openCreateDialog,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: token == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Add DEV_AUTH_BEARER_TOKEN to list assignments.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<dynamic>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(snapshot.error.toString()),
                              const SizedBox(height: 16),
                              FilledButton.tonal(onPressed: _refresh, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  final items = snapshot.data ?? const [];
                  if (items.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('No assignments yet')),
                      ],
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final m = items[i] as Map<String, dynamic>;
                      final id = m['id']?.toString() ?? '';
                      final name = m['decedent_name']?.toString() ?? '—';
                      final status = m['status']?.toString() ?? '—';
                      return ListTile(
                        onTap: id.isEmpty
                            ? null
                            : () async {
                                await context.push('/assignments/$id', extra: m);
                              },
                        title: Text(name),
                        subtitle: Text(
                          '${m['pickup_address']?.toString() ?? ''}\nContact: ${m['contact_name']?.toString() ?? '-'} (${m['contact_phone']?.toString() ?? '-'})',
                        ),
                        trailing: PopupMenuButton<String>(
                          enabled: !_submitting && id.isNotEmpty,
                          tooltip: 'Update status',
                          onSelected: (nextStatus) {
                            if (nextStatus != status && id.isNotEmpty) {
                              _changeStatus(assignmentId: id, status: nextStatus);
                            }
                          },
                          itemBuilder: (context) {
                            return AssignmentsRepository.statuses
                                .map(
                                  (s) => PopupMenuItem<String>(
                                    value: s,
                                    child: Row(
                                      children: [
                                        if (s == status) const Icon(Icons.check, size: 16) else const SizedBox(width: 16),
                                        const SizedBox(width: 8),
                                        Text(s),
                                      ],
                                    ),
                                  ),
                                )
                                .toList();
                          },
                          child: Chip(
                            label: Text(status, style: const TextStyle(fontSize: 12)),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        isThreeLine: true,
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}

class _CreateAssignmentDialog extends StatefulWidget {
  const _CreateAssignmentDialog();

  @override
  State<_CreateAssignmentDialog> createState() => _CreateAssignmentDialogState();
}

class _CreateAssignmentDialogState extends State<_CreateAssignmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _decedentName = TextEditingController();
  final _pickupAddress = TextEditingController();
  final _contactName = TextEditingController();
  final _contactPhone = TextEditingController();
  final _notes = TextEditingController();
  var _submitting = false;

  @override
  void dispose() {
    _decedentName.dispose();
    _pickupAddress.dispose();
    _contactName.dispose();
    _contactPhone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final token = staffBearerToken();
    if (token == null) return;
    setState(() => _submitting = true);
    try {
      await context.read<AppRepositories>().assignments.createAssignment(
            bearerToken: token,
            payload: {
              'decedent_name': _decedentName.text.trim(),
              'pickup_address': _pickupAddress.text.trim(),
              'contact_name': _contactName.text.trim(),
              'contact_phone': _contactPhone.text.trim(),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create assignment'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _decedentName,
                  decoration: const InputDecoration(labelText: 'Decedent name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _pickupAddress,
                  decoration: const InputDecoration(labelText: 'Pickup address'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _contactName,
                  decoration: const InputDecoration(labelText: 'Contact name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _contactPhone,
                  decoration: const InputDecoration(labelText: 'Contact phone'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notes,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Create'),
        ),
      ],
    );
  }
}
