import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:funeralface_mobile/app/app_repositories.dart';
import 'package:funeralface_mobile/app/session/staff_auth.dart';
import 'package:funeralface_mobile/core/env.dart';
import 'package:funeralface_mobile/core/family_share_token.dart';
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

  String? _shareToken;
  String? _shareExpiresIso;
  var _shareOneTime = false;

  @override
  void initState() {
    super.initState();
    _decedentName = TextEditingController(text: widget.initial['decedent_name']?.toString() ?? '');
    _pickupAddress = TextEditingController(text: widget.initial['pickup_address']?.toString() ?? '');
    _contactName = TextEditingController(text: widget.initial['contact_name']?.toString() ?? '');
    _contactPhone = TextEditingController(text: widget.initial['contact_phone']?.toString() ?? '');
    _notes = TextEditingController(text: widget.initial['notes']?.toString() ?? '');
    _status = widget.initial['status']?.toString() ?? 'pending';
    _readShareFromMap(widget.initial);
  }

  void _readShareFromMap(Map<String, dynamic> map) {
    final t = map['share_token']?.toString().trim();
    _shareToken = (t != null && t.isNotEmpty) ? t : null;
    _shareExpiresIso = map['share_token_expires_at']?.toString();
    _shareOneTime = map['share_token_one_time'] == true;
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

  void _applyAssignmentResponse(Map<String, dynamic> body) {
    if (!mounted) return;
    setState(() => _readShareFromMap(body));
  }

  Future<void> _save() async {
    final token = staffBearerToken();
    if (token == null) return;
    setState(() => _saving = true);
    try {
      final body = await context.read<AppRepositories>().assignments.updateAssignment(
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
      _applyAssignmentResponse(body);
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
      final body = await context.read<AppRepositories>().assignments.updateAssignment(
            assignmentId: widget.assignmentId,
            bearerToken: token,
            payload: {'status': next},
          );
      if (!mounted) return;
      _applyAssignmentResponse(body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assignment status updated to $next')),
      );
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

  Future<void> _copyFamilyLink() async {
    final t = _shareToken;
    if (t == null || t.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: AppEnv.familyShareUrlForToken(t)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied')));
  }

  Future<void> _issueShareTokenAndCopy() async {
    final token = staffBearerToken();
    if (token == null) return;
    final newToken = generateFamilyShareToken();
    setState(() => _saving = true);
    try {
      final body = await context.read<AppRepositories>().assignments.updateAssignment(
            assignmentId: widget.assignmentId,
            bearerToken: token,
            payload: {'share_token': newToken},
          );
      if (!mounted) return;
      _applyAssignmentResponse(body);
      await Clipboard.setData(ClipboardData(text: AppEnv.familyShareUrlForToken(newToken)));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New family link saved and copied')),
      );
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

  Future<void> _revokeFamilyLink() async {
    final token = staffBearerToken();
    if (token == null) return;
    setState(() => _saving = true);
    try {
      final body = await context.read<AppRepositories>().assignments.updateAssignment(
            assignmentId: widget.assignmentId,
            bearerToken: token,
            payload: {'share_token': null},
          );
      if (!mounted) return;
      _applyAssignmentResponse(body);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Family link revoked')));
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

  Future<void> _confirmRegenerate() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Regenerate family link?'),
        content: const Text(
          'Anyone with the old link will no longer see status. A new link will be created and copied.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Regenerate')),
        ],
      ),
    );
    if (ok == true && mounted) await _issueShareTokenAndCopy();
  }

  Future<void> _confirmRevoke() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke family link?'),
        content: const Text('Family members will not be able to open the status page with this link.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Revoke')),
        ],
      ),
    );
    if (ok == true && mounted) await _revokeFamilyLink();
  }

  @override
  Widget build(BuildContext context) {
    final token = staffBearerToken();
    final shareUrl =
        (_shareToken != null && _shareToken!.isNotEmpty) ? AppEnv.familyShareUrlForToken(_shareToken!) : null;

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
                  SelectableText(shareUrl, style: Theme.of(context).textTheme.bodyMedium),
                  if (_shareExpiresIso != null && _shareExpiresIso!.isNotEmpty)
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
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _saving ? null : _copyFamilyLink,
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy link'),
                      ),
                      OutlinedButton(
                        onPressed: _saving ? null : _confirmRegenerate,
                        child: const Text('Regenerate'),
                      ),
                      OutlinedButton(
                        onPressed: _saving ? null : _confirmRevoke,
                        child: const Text('Revoke'),
                      ),
                    ],
                  ),
                ] else ...[
                  FilledButton.icon(
                    onPressed: _saving ? null : _issueShareTokenAndCopy,
                    icon: const Icon(Icons.link),
                    label: const Text('Create & copy link'),
                  ),
                ],
              ],
            ),
    );
  }
}
