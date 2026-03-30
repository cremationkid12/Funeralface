import 'package:flutter/material.dart';
import 'package:funeralface_mobile/app/app_repositories.dart';
import 'package:funeralface_mobile/app/session/staff_auth.dart';
import 'package:funeralface_mobile/features/dashboard/dashboard_usecase.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<DashboardOverview>? _overviewFuture;
  var _depsReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_depsReady) {
      _depsReady = true;
      _overviewFuture = _load();
    }
  }

  Future<DashboardOverview> _load() {
    final repos = context.read<AppRepositories>();
    return repos.dashboard.loadOverview(bearerToken: staffBearerToken());
  }

  Future<void> _refresh() async {
    setState(() {
      _overviewFuture = _load();
    });
    await _overviewFuture;
  }

  @override
  Widget build(BuildContext context) {
    final token = staffBearerToken();

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (token == null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Sign-in is not wired yet. Use a dev JWT to see live counts.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else
              FutureBuilder<DashboardOverview>(
                future: _overviewFuture,
                builder: (context, snapshot) {
                  if (_overviewFuture == null) {
                    return const SizedBox.shrink();
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return _ErrorCard(
                      message: snapshot.error.toString(),
                      onRetry: _refresh,
                    );
                  }
                  final s = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _StatCard(
                        title: 'Staff',
                        value: '${s.staffCount}',
                        icon: Icons.people_outline,
                      ),
                      const SizedBox(height: 12),
                      _StatCard(
                        title: 'Active assignments',
                        value: '${s.activeAssignments}',
                        icon: Icons.local_shipping_outlined,
                      ),
                      const SizedBox(height: 12),
                      _StatCard(
                        title: 'Completed',
                        value: '${s.completedAssignments}',
                        icon: Icons.check_circle_outline,
                      ),
                      if (s.recentAssignments.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text('Recent assignments', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              for (var i = 0; i < s.recentAssignments.length; i++) ...[
                                if (i > 0) const Divider(height: 1),
                                Builder(
                                  builder: (context) {
                                    final m = s.recentAssignments[i];
                                    final name = m['decedent_name']?.toString() ?? '—';
                                    final status = m['status']?.toString() ?? '—';
                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      subtitle: Text(
                                        m['pickup_address']?.toString() ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: Chip(
                                        label: Text(status, style: const TextStyle(fontSize: 11)),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Could not load dashboard', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
