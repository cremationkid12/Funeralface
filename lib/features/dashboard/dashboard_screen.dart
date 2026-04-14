import 'package:flutter/material.dart';
import 'package:funeralface_mobile/app/app_repositories.dart';
import 'package:funeralface_mobile/app/session/auth_session.dart';
import 'package:funeralface_mobile/app/session/staff_auth.dart';
import 'package:funeralface_mobile/core/env.dart';
import 'package:funeralface_mobile/core/network/api_client.dart';
import 'package:funeralface_mobile/core/theme/app_theme.dart';
import 'package:funeralface_mobile/core/widgets/app_status_chip.dart';
import 'package:funeralface_mobile/features/auth/backend_provision.dart';
import 'package:funeralface_mobile/features/dashboard/dashboard_usecase.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
  void initState() {
    super.initState();
    AuthSession.instance.addListener(_onAuthSessionChanged);
  }

  @override
  void dispose() {
    AuthSession.instance.removeListener(_onAuthSessionChanged);
    super.dispose();
  }

  void _onAuthSessionChanged() {
    if (!mounted) return;
    final token = staffBearerToken();
    if (token != null) {
      setState(() => _overviewFuture = _load());
    } else {
      setState(() => _overviewFuture = null);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_depsReady) {
      _depsReady = true;
      final token = staffBearerToken();
      if (token != null) _overviewFuture = _load();
    }
  }

  Future<DashboardOverview> _load() async {
    final token = staffBearerToken();
    if (token == null || token.isEmpty) throw StateError('Not signed in');
    final api = context.read<ApiClient>();
    final repos = context.read<AppRepositories>();
    if (AppEnv.hasSupabaseAuthConfig) {
      try {
        await ensureBackendProvisioned(api, token);
      } catch (_) {}
    }
    return repos.dashboard.loadOverview(bearerToken: token);
  }

  Future<void> _refresh() async {
    setState(() => _overviewFuture = _load());
    await _overviewFuture;
  }

  Future<void> _linkAccountOnServer() async {
    final token = staffBearerToken();
    if (token == null || !mounted) return;
    final api = context.read<ApiClient>();
    try {
      await ensureBackendProvisioned(api, token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account linked. Loading dashboard…')),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = staffBearerToken();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Green header ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _DashboardHeader(),
            ),

            // ── Content ────────────────────────────────────────────────────
            if (token == null)
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: _UnauthCard(),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                sliver: SliverToBoxAdapter(
                  child: FutureBuilder<DashboardOverview>(
                    future: _overviewFuture,
                    builder: (context, snapshot) {
                      if (_overviewFuture == null) {
                        return const SizedBox.shrink();
                      }
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        final msg = snapshot.error.toString();
                        final notProvisioned = msg.contains('not provisioned') ||
                            msg.contains('Account is not provisioned');
                        return _ErrorCard(
                          message: msg,
                          onRetry: _refresh,
                          onLinkServer:
                              notProvisioned ? _linkAccountOnServer : null,
                        );
                      }
                      final data = snapshot.data!;
                      return _DashboardBody(
                        overview: data,
                        onSeeAll: () => context.go('/assignments'),
                        onAssignmentTap: (m) => context.go(
                          '/assignments/${m['id']}',
                          extra: m,
                        ),
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

// ── Header ─────────────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  static String _dateString() {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final now = DateTime.now();
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        24,
      ),
      child: Row(
        children: [
          // Avatar placeholder
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white38, width: 1.5),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()}!',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _dateString(),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // Notification bell
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_outlined,
                color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }
}

// ── Dashboard body (loaded state) ─────────────────────────────────────────────

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.overview,
    required this.onSeeAll,
    required this.onAssignmentTap,
  });

  final DashboardOverview overview;
  final VoidCallback onSeeAll;
  final ValueChanged<Map<String, dynamic>> onAssignmentTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Stat cards row ────────────────────────────────────────────────
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Staff',
                  value: '${overview.staffCount}',
                  icon: Icons.people_rounded,
                  cardColor: const Color(0xFF2D6A4F),
                  isCenter: false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  title: 'Active Assignments',
                  value: '${overview.activeAssignments}',
                  icon: Icons.local_shipping_rounded,
                  cardColor: const Color(0xFF2F4858),
                  isCenter: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  title: 'Completed',
                  value: '${overview.completedAssignments}',
                  icon: Icons.check_circle_rounded,
                  cardColor: const Color(0xFF8B7355),
                  isCenter: false,
                ),
              ),
            ],
          ),
        ),

        if (overview.recentAssignments.isNotEmpty) ...[
          const SizedBox(height: 28),
          // ── Section header ───────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Assignments',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              GestureDetector(
                onTap: onSeeAll,
                child: Text(
                  'See All',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Assignment rows ───────────────────────────────────────────────
          ...overview.recentAssignments.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AssignmentRow(
                  data: m,
                  onTap: () => onAssignmentTap(m),
                ),
              )),
        ],
      ],
    );
  }
}

// ── Stat card ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.cardColor,
    required this.isCenter,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color cardColor;
  final bool isCenter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: isCenter ? 20 : 16,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isCenter ? 32 : 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent assignment row ──────────────────────────────────────────────────────

class _AssignmentRow extends StatelessWidget {
  const _AssignmentRow({required this.data, required this.onTap});

  final Map<String, dynamic> data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = data['decedent_name']?.toString() ?? '—';
    final address = data['pickup_address']?.toString() ?? '';
    final status = data['status']?.toString() ?? '';
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join()
        : '?';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar with initials
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
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 12,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            address,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textSecondary,
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
            const SizedBox(width: 8),
            AppStatusChip(status: status),
          ],
        ),
      ),
    );
  }
}

// ── Unauthenticated state ──────────────────────────────────────────────────────

class _UnauthCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppEnv.hasSupabaseAuthConfig
                ? 'You are not signed in.'
                : 'Supabase auth is not configured.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (AppEnv.hasSupabaseAuthConfig) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go('/auth'),
              child: const Text('Go to sign in'),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Error state ────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
    this.onLinkServer,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onLinkServer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.statusCancelledBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.statusCancelledFg.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.statusCancelledFg, size: 20),
              const SizedBox(width: 8),
              Text(
                'Could not load dashboard',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.statusCancelledFg,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.statusCancelledFg),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
              if (onLinkServer != null)
                OutlinedButton(
                  onPressed: onLinkServer,
                  child: const Text('Link account'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
