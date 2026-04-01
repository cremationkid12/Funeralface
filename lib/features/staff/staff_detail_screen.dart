import 'package:flutter/material.dart';
import 'package:funeralface_mobile/app/app_repositories.dart';
import 'package:funeralface_mobile/app/session/staff_auth.dart';
import 'package:funeralface_mobile/core/network/api_client.dart';
import 'package:funeralface_mobile/features/staff/staff_repository.dart';
import 'package:provider/provider.dart';

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
  String _role = 'user';
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial['name']?.toString() ?? '');
    _phone = TextEditingController(text: widget.initial['phone']?.toString() ?? '');
    _email = TextEditingController(text: widget.initial['email']?.toString() ?? '');
    final r = widget.initial['role']?.toString();
    _role = r != null && StaffRepository.roles.contains(r) ? r : 'user';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
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
        'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
      };
      await context.read<AppRepositories>().staff.updateStaff(
            id: widget.staffId,
            payload: payload,
            bearerToken: token,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff member saved')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove staff member?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final token = staffBearerToken();
    if (token == null) return;
    setState(() => _busy = true);
    try {
      await context.read<AppRepositories>().staff.deleteStaff(id: widget.staffId, bearerToken: token);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff member removed')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = staffBearerToken();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff member'),
        actions: [
          TextButton(
            onPressed: token == null || _busy ? null : _save,
            child: _busy
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
                  'Add DEV_AUTH_BEARER_TOKEN to edit staff.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _email,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: StaffRepository.roles
                      .map((r) => DropdownMenuItem<String>(value: r, child: Text(r)))
                      .toList(),
                  onChanged: _busy
                      ? null
                      : (v) {
                          if (v != null) setState(() => _role = v);
                        },
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _confirmDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove staff member'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
    );
  }
}
