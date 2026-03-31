import 'package:flutter/material.dart';
import 'package:funeralface_mobile/app/app_repositories.dart';
import 'package:funeralface_mobile/app/session/staff_auth.dart';
import 'package:funeralface_mobile/core/network/api_client.dart';
import 'package:funeralface_mobile/features/assignments/assignments_repository.dart';
import 'package:provider/provider.dart';

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
  late final TextEditingController _decedentName;
  late final TextEditingController _pickupAddress;
  late final TextEditingController _contactName;
  late final TextEditingController _contactPhone;
  late final TextEditingController _notes;

  var _saving = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _decedentName = TextEditingController(text: widget.initial['decedent_name']?.toString() ?? '');
    _pickupAddress = TextEditingController(text: widget.initial['pickup_address']?.toString() ?? '');
    _contactName = TextEditingController(text: widget.initial['contact_name']?.toString() ?? '');
    _contactPhone = TextEditingController(text: widget.initial['contact_phone']?.toString() ?? '');
    _notes = TextEditingController(text: widget.initial['notes']?.toString() ?? '');
    _status = widget.initial['status']?.toString() ?? 'pending';
  }

  @override
  void dispose() {
    _decedentName.dispose();
    _pickupAddress.dispose();
    _contactName.dispose();
    _contactPhone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final token = staffBearerToken();
    if (token == null) return;
    setState(() => _saving = true);
    try {
      await context.read<AppRepositories>().assignments.updateAssignment(
            assignmentId: widget.assignmentId,
            bearerToken: token,
            payload: {
              'decedent_name': _decedentName.text.trim(),
              'pickup_address': _pickupAddress.text.trim(),
              'contact_name': _contactName.text.trim(),
              'contact_phone': _contactPhone.text.trim(),
              'notes': _notes.text.trim(),
            },
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assignment saved')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setStatus(String next) async {
    final token = staffBearerToken();
    if (token == null) return;
    setState(() {
      _saving = true;
      _status = next;
    });
    try {
      await context.read<AppRepositories>().assignments.updateAssignment(
            assignmentId: widget.assignmentId,
            bearerToken: token,
            payload: {'status': next},
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $next')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = staffBearerToken();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment'),
        actions: [
          TextButton(
            onPressed: token == null || _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: token == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Add DEV_AUTH_BEARER_TOKEN to view and edit assignment details.',
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
                      onChanged: _saving ? null : (v) => v == null ? null : _setStatus(v),
                      items: AssignmentsRepository.statuses
                          .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
                          .toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
              ],
            ),
    );
  }
}

