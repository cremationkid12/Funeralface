import 'package:flutter/material.dart';
import 'package:funeralface_mobile/app/app_repositories.dart';
import 'package:funeralface_mobile/app/session/staff_auth.dart';
import 'package:provider/provider.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  Future<List<dynamic>>? _future;
  var _depsReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_depsReady) {
      _depsReady = true;
      _future = _load();
    }
  }

  Future<List<dynamic>> _load() {
    return context.read<AppRepositories>().staff.listStaff(bearerToken: staffBearerToken());
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final token = staffBearerToken();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff'),
        actions: [
          IconButton(
            tooltip: 'Invite (uses backend Supabase config)',
            onPressed: token == null
                ? null
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invite flow: add dialog + POST /v1/staff/invite in a follow-up.'),
                      ),
                    );
                  },
            icon: const Icon(Icons.person_add_outlined),
          ),
        ],
      ),
      body: token == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Add DEV_AUTH_BEARER_TOKEN to list staff.',
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
                        Center(child: Text('No staff yet')),
                      ],
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final m = items[i] as Map<String, dynamic>;
                      final name = m['name']?.toString() ?? '—';
                      final phone = m['phone']?.toString() ?? '';
                      final role = m['role']?.toString() ?? '';
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(name),
                        subtitle: Text(phone),
                        trailing: role.isEmpty ? null : Chip(label: Text(role, style: const TextStyle(fontSize: 11))),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}
