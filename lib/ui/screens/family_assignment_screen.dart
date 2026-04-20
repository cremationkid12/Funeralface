import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:funeralface_mobile/app/app_repositories.dart';
import 'package:funeralface_mobile/core/theme/app_theme.dart';
import 'package:funeralface_mobile/services/family_assignment_services.dart';
import 'package:funeralface_mobile/features/family/family_assignment_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// Family-facing status screen (public token; no staff JWT.)
class FamilyAssignmentScreen extends StatefulWidget {
  const FamilyAssignmentScreen({super.key, required this.token});

  final String token;

  @override
  State<FamilyAssignmentScreen> createState() => _FamilyAssignmentScreenState();
}

class _FamilyAssignmentScreenState extends State<FamilyAssignmentScreen> {
  Future<FamilyAssignmentResult>? _future;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final repos = context.read<AppRepositories>();
    setState(() {
      _future = repos.familyAssignments.getByToken(widget.token.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<FamilyAssignmentResult>(
          future: _future,
          builder: (context, snapshot) {
            if (_future == null ||
                snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (snapshot.hasError) {
              return _FamilyMessage(
                title: 'Something went wrong',
                body:
                    'Please try again later or contact the funeral home.',
                onRetry: _load,
              );
            }
            final result = snapshot.data!;
            if (!result.isOk) {
              return _FamilyMessage(
                title: _failureTitle(result.failureCode),
                body: _failureBody(result),
                onRetry: _load,
              );
            }
            final v = result.view!;
            return _ServiceStatusCard(view: v, onClose: _maybePop);
          },
        ),
      ),
    );
  }

  void _maybePop() => Navigator.of(context).maybePop();

  static String _failureTitle(FamilyAssignmentFailure? code) {
    switch (code) {
      case FamilyAssignmentFailure.notFound:
        return 'Link not available';
      case FamilyAssignmentFailure.expired:
        return 'Link has expired';
      case FamilyAssignmentFailure.rateLimited:
        return 'Please wait and try again';
      case FamilyAssignmentFailure.unknown:
      case null:
        return 'Unable to load';
    }
  }

  static String _failureBody(FamilyAssignmentResult result) {
    switch (result.failureCode) {
      case FamilyAssignmentFailure.notFound:
      case FamilyAssignmentFailure.expired:
        return 'If you need help, please contact the funeral home directly.';
      case FamilyAssignmentFailure.rateLimited:
        return 'Too many requests were made from this device.';
      default:
        return result.message ?? 'Something went wrong.';
    }
  }
}

// ── Service status card ────────────────────────────────────────────────────────

class _ServiceStatusCard extends StatelessWidget {
  const _ServiceStatusCard({required this.view, required this.onClose});

  final FamilyAssignmentView view;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final phone = view.supportContactPhone.trim();

    return Column(
      children: [
        // Top spacing so the white card looks like a bottom sheet on a blurred bg
        const Spacer(),

        // ── Main card ────────────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 0),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button (top right)
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: onClose,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.accentSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: AppColors.accent, size: 20),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Title
              Text(
                'Service status',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'We are here for your family.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 24),

              // ── Info rows ──────────────────────────────────────────────────
              _InfoRow(
                icon: Icons.local_shipping_outlined,
                label: 'Status',
                value: _formatStatus(view.status),
              ),
              if (view.decedentName.isNotEmpty) ...[
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Name',
                  value: view.decedentName,
                ),
              ],
              if (view.etaNote != null &&
                  view.etaNote!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.notes_rounded,
                  label: 'Note',
                  value: view.etaNote!.trim(),
                ),
              ],

              // ── Call button ────────────────────────────────────────────────
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 28),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => _call(phone),
                    icon: const Icon(Icons.phone_rounded, size: 18),
                    label: Text('Call $phone'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static String _formatStatus(String raw) {
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty
            ? w
            : w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  Future<void> _call(String phone) async {
    final uri =
        Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'\s'), ''));
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

// ── Info row ───────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accentSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error / message state ──────────────────────────────────────────────────────

class _FamilyMessage extends StatelessWidget {
  const _FamilyMessage({
    required this.title,
    required this.body,
    required this.onRetry,
  });

  final String title;
  final String body;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.accentSurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline_rounded,
                    color: AppColors.accent, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
