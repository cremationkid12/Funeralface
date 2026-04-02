import 'package:flutter/material.dart';
import 'package:funeralface_mobile/app/app_repositories.dart';
import 'package:funeralface_mobile/app/session/staff_auth.dart';
import 'package:funeralface_mobile/core/network/api_client.dart';
import 'package:funeralface_mobile/features/staff/staff_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  List<dynamic> _items = const [];
  bool _loading = true;
  Object? _error;
  var _depsReady = false;
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
      if (!mounted) return;
      setState(() {
        _items = const [];
        _loading = false;
        _error = null;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await context.read<AppRepositories>().staff.listStaff(bearerToken: token);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _load();
  }

  Future<void> _openCreateDialog() async {
    final created = await showDialog<Map<String, dynamic>? >(
      context: context,
      builder: (context) => const _CreateStaffDialog(),
    );
    if (created == null || !mounted) return;
    // Some mocks/backends may return only `id` for create; in that case,
    // fall back to refresh so the list has full row fields.
    final hasRequiredFields = created['name'] != null && created['phone'] != null;
    if (!hasRequiredFields) {
      await _refresh();
      return;
    }

    setState(() => _items = [created, ..._items]);
  }

  Future<void> _openInviteDialog() async {
    final invited = await showDialog<bool>(
      context: context,
      builder: (context) => const _InviteStaffDialog(),
    );
    if (invited == true && mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final token = staffBearerToken();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff'),
        actions: [
          IconButton(
            tooltip: 'Invite by email (admin + Supabase)',
            onPressed: token == null ? null : _openInviteDialog,
            icon: const Icon(Icons.mail_outline),
          ),
          IconButton(
            tooltip: 'Add staff member',
            onPressed: token == null ? null : _openCreateDialog,
            icon: const Icon(Icons.person_add_outlined),
          ),
        ],
      ),
      body: token == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Please sign in to load staff.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _loading
                  ? ListView(
                      physics: AlwaysScrollableScrollPhysics(),
                      children: [SizedBox(height: 120), Center(child: CircularProgressIndicator())],
                    )
                  : _error != null
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _friendlyErrorText(context, _error),
                                  const SizedBox(height: 16),
                                  FilledButton.tonal(onPressed: _refresh, child: const Text('Retry')),
                                ],
                              ),
                            ),
                          ],
                        )
                      : _items.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 120),
                                Center(child: Text('No staff yet')),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final m = _items[i] as Map<String, dynamic>;
                                final id = m['id']?.toString() ?? '';
                                final name = m['name']?.toString() ?? '—';
                                final phone = m['phone']?.toString() ?? '';
                                final role = m['role']?.toString() ?? '';
                                return ListTile(
                                  leading: const CircleAvatar(child: Icon(Icons.person)),
                                  title: Text(name),
                                  subtitle: Text(phone),
                                  trailing: role.isEmpty ? null : Chip(label: Text(role, style: const TextStyle(fontSize: 11))),
                                  onTap: id.isEmpty
                                      ? null
                                      : () async {
                                          final result = await context.push<Map<String, dynamic>>('/staff/$id', extra: m);
                                          if (result == null || !mounted) return;
                                          if (result['deleted'] == true) {
                                            _items = _items.where((it) => it['id']?.toString() != id).toList();
                                            setState(() {});
                                            return;
                                          }
                                          final hasRequiredFields = result['name'] != null && result['phone'] != null;
                                          if (!hasRequiredFields) {
                                            await _refresh();
                                            return;
                                          }
                                          final idx = _items.indexWhere((it) => it['id']?.toString() == id);
                                          if (idx >= 0) {
                                            _items[idx] = result;
                                          } else {
                                            _items = [result, ..._items];
                                          }
                                          setState(() {});
                                        },
                                );
                              },
                            ),
            ),
    );
  }
}

Widget _friendlyErrorText(BuildContext context, Object? error) {
  if (error is ApiException) {
    if (error.statusCode == 403) {
      return const Text('Admin role required to manage staff.');
    }
  }
  return Text(error.toString());
}

class _InviteStaffDialog extends StatefulWidget {
  const _InviteStaffDialog();

  @override
  State<_InviteStaffDialog> createState() => _InviteStaffDialogState();
}

class _InviteStaffDialogState extends State<_InviteStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  var _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  bool _looksLikeEmail(String v) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final token = staffBearerToken();
    if (token == null) return;
    setState(() => _submitting = true);
    try {
      await context.read<AppRepositories>().staff.inviteByEmail(
            email: _email.text,
            bearerToken: token,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite sent (check email / Supabase config).')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      final msg = e.statusCode == 403
          ? 'Forbidden: admin role required to invite.'
          : e.message;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
      title: const Text('Invite staff'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            if (!_looksLikeEmail(v)) return 'Enter a valid email';
            return null;
          },
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
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send invite'),
        ),
      ],
    );
  }
}

class _CreateStaffDialog extends StatefulWidget {
  const _CreateStaffDialog();

  @override
  State<_CreateStaffDialog> createState() => _CreateStaffDialogState();
}

class _CreateStaffDialogState extends State<_CreateStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  String _role = 'user';
  var _submitting = false;

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
      final created = await context.read<AppRepositories>().staff.createStaff(
            payload: payload,
            bearerToken: token,
          );
      if (!mounted) return;
      Navigator.of(context).pop(created);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff member created')));
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
      title: const Text('Add staff member'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phone,
                  decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email (optional)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                  items: StaffRepository.roles
                      .map((r) => DropdownMenuItem<String>(value: r, child: Text(r)))
                      .toList(),
                  onChanged: _submitting ? null : (v) => setState(() => _role = v ?? 'user'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
