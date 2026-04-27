import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:everroute/features/session/auth_session.dart';
import 'package:everroute/features/session/staff_auth.dart';
import 'package:everroute/core/env.dart';
import 'package:everroute/core/network/api_client.dart';
import 'package:everroute/core/theme/app_theme.dart';
import 'package:everroute/features/dashboard/dashboard_cubit.dart';
import 'package:everroute/ui/widgets/app_status_chip.dart';
import 'package:everroute/ui/screens/dashboard/widgets/stat_card.dart';
import 'package:everroute/features/dashboard/dashboard_state.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:everroute/services/auth_services.dart';

const double _kStatCardOverlap = 70;
const double _kHeaderBottomPadding = 90;
const double _kHeaderHorizontal = 20;
const double _kHeaderRadius = 28;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardCubit _dashboardCubit;
  var _depsReady = false;

  @override
  void initState() {
    super.initState();
    _dashboardCubit = context.read<DashboardCubit>();
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
      _dashboardCubit.load(bearerToken: token);
    } else {
      _dashboardCubit.clear();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_depsReady) {
      _depsReady = true;
      final token = staffBearerToken();
      if (token != null) {
        _dashboardCubit.load(bearerToken: token);
      }
    }
  }

  Future<void> _refresh() async {
    final token = staffBearerToken();
    if (token == null) return;
    await _dashboardCubit.refresh(bearerToken: token);
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
      await _dashboardCubit.refresh(bearerToken: token);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = staffBearerToken();

    return BlocProvider.value(
      value: _dashboardCubit,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          child: token == null
              ? _guestScrollView()
              : BlocBuilder<DashboardCubit, DashboardState>(
                  builder: (context, state) =>
                      _signedInScrollView(context, state),
                ),
        ),
      ),
    );
  }

  Widget _guestScrollView() {
    return const CustomScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _DashboardHeader()),
        SliverPadding(
          padding: EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(child: _UnauthCard()),
        ),
      ],
    );
  }

  Widget _signedInScrollView(BuildContext context, DashboardState state) {
    final overview = state.overview;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _DashboardHeader(overview: overview)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          sliver: SliverToBoxAdapter(child: _overviewPanel(context, state)),
        ),
      ],
    );
  }

  Widget _overviewPanel(BuildContext context, DashboardState state) {
    if (state.busy && state.overview == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (state.error != null && state.overview == null) {
      final msg = state.error!;
      final notProvisioned =
          msg.contains('not provisioned') ||
          msg.contains('Account is not provisioned');
      return _ErrorCard(
        message: msg,
        onRetry: _refresh,
        onLinkServer: notProvisioned ? _linkAccountOnServer : null,
      );
    }
    final data = state.overview;
    if (data == null) return const SizedBox.shrink();
    return _DashboardBody(
      overview: data,
      onSeeAll: () => context.go('/assignments'),
      onAssignmentTap: (m) => context.go('/assignments/${m['id']}', extra: m),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({this.overview});

  /// When non-null, stat cards are shown overlapping the bottom of the header.
  final DashboardOverview? overview;

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  static String _dateString() {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final now = DateTime.now();
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  /// Returns the user's first name from Supabase metadata or email prefix.
  static String _firstName() {
    if (!AppEnv.hasSupabaseAuthConfig) return '';
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return '';
      final meta = user.userMetadata;
      final full =
          meta?['full_name']?.toString() ?? meta?['name']?.toString() ?? '';
      if (full.trim().isNotEmpty) return full.trim().split(' ').first;
      final email = user.email ?? '';
      if (email.isNotEmpty) return email.split('@').first;
    } catch (_) {}
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _firstName();
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : null;
    final overviewData = overview;
    final topPad = MediaQuery.of(context).padding.top + 12;
    final cardsBelowHeader = kStatCardMinHeight - _kStatCardOverlap;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                _kHeaderHorizontal,
                topPad,
                _kHeaderHorizontal,
                _kHeaderBottomPadding,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3E8C73), Color(0xFF2F7B66)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(_kHeaderRadius),
                  bottomRight: Radius.circular(_kHeaderRadius),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: initial != null
                          ? Text(
                              initial,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 28,
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          firstName.isNotEmpty
                              ? '${_greeting()} $firstName!'
                              : '${_greeting()}!',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _dateString(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_rounded,
                      color: Color(0xFFEF8A2F),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            if (overviewData != null)
              Positioned(
                left: _kHeaderHorizontal,
                right: _kHeaderHorizontal,
                bottom: -cardsBelowHeader,
                height: kStatCardMinHeight,
                child: _DashboardStatCards(overview: overviewData),
              ),
          ],
        ),
        if (overviewData != null) SizedBox(height: cardsBelowHeader),
      ],
    );
  }
}

class _DashboardStatCards extends StatelessWidget {
  const _DashboardStatCards({required this.overview});

  final DashboardOverview overview;

  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: StatCard(
            title: 'Staff',
            value: '${overview.staffCount}',
            icon: Icons.people_rounded,
            gradient: const [Color(0xFF8AB373), Color(0xFF4D8F55)],
          ),
        ),
        const SizedBox(width: _gap),
        Expanded(
          child: StatCard(
            title: 'Active Assignments',
            value: '${overview.activeAssignments}',
            icon: Icons.local_shipping_rounded,
            gradient: const [Color(0xFF6B9ED0), Color(0xFF2B557F)],
          ),
        ),
        const SizedBox(width: _gap),
        Expanded(
          child: StatCard(
            title: 'Completed',
            value: '${overview.completedAssignments}',
            icon: Icons.assignment_turned_in_rounded,
            gradient: const [Color(0xFFC8AD68), Color(0xFF8A7346)],
          ),
        ),
      ],
    );
  }
}

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
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Assignments',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppColors.accent,
              ),
              child: Text(
                'See All',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (overview.recentAssignments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: _RecentAssignmentsEmpty(),
          )
        else
          ...overview.recentAssignments.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AssignmentRow(data: m, onTap: () => onAssignmentTap(m)),
            ),
          ),
      ],
    );
  }
}

/// Matches [assignments_screen.dart] `_EmptyBody` when `hasSearch` is false.
class _RecentAssignmentsEmpty extends StatelessWidget {
  const _RecentAssignmentsEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.assignment_outlined,
            size: 56,
            color: AppColors.border,
          ),
          const SizedBox(height: 12),
          Text(
            'No assignments yet',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AssignmentRow extends StatelessWidget {
  const _AssignmentRow({required this.data, required this.onTap});

  final Map<String, dynamic> data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = data['decedent_name']?.toString() ?? '—';
    final address = data['pickup_address']?.toString() ?? '';
    final status = data['status']?.toString() ?? '';
    final assignedStaffName =
        data['assigned_staff_name']?.toString().trim() ?? '';
    final assignedStaffProfileImageUrl =
        data['assigned_staff_profile_image_url']?.toString().trim() ?? '';
    final initials = assignedStaffName.isNotEmpty
        ? assignedStaffName
              .split(' ')
              .map((w) => w.isNotEmpty ? w[0] : '')
              .take(2)
              .join()
        : '?';

    const radius = 14.0;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: assignedStaffProfileImageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          assignedStaffProfileImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _AssignedStaffInitialsAvatar(initials: initials),
                        ),
                      )
                    : _AssignedStaffInitialsAvatar(initials: initials),
              ),
              const SizedBox(width: 12),
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
      ),
    );
  }
}

class _AssignedStaffInitialsAvatar extends StatelessWidget {
  const _AssignedStaffInitialsAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _UnauthCard extends StatelessWidget {
  const _UnauthCard();

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
        border: Border.all(
          color: AppColors.statusCancelledFg.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.statusCancelledFg,
                size: 20,
              ),
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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.statusCancelledFg),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
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
