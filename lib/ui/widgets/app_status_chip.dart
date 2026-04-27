import 'package:flutter/material.dart';
import 'package:everroute/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colour-coded chip for the 6 assignment status values.
class AppStatusChip extends StatelessWidget {
  const AppStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final cfg = _statusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cfg.icon, size: 12, color: cfg.fg),
          const SizedBox(width: 4),
          Text(
            cfg.label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cfg.fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// Returns the display label for a raw API status string.
String statusLabel(String raw) => _statusConfig(raw).label;

class _StatusConfig {
  const _StatusConfig({
    required this.label,
    required this.fg,
    required this.bg,
    required this.icon,
  });
  final String label;
  final Color fg;
  final Color bg;
  final IconData icon;
}

_StatusConfig _statusConfig(String raw) {
  switch (raw.toLowerCase()) {
    case 'pending':
      return const _StatusConfig(
        label: 'Pending',
        fg: AppColors.statusPendingFg,
        bg: AppColors.statusPendingBg,
        icon: Icons.schedule_rounded,
      );
    case 'assigned':
      return const _StatusConfig(
        label: 'Assigned',
        fg: AppColors.statusAssignedFg,
        bg: AppColors.statusAssignedBg,
        icon: Icons.person_pin_rounded,
      );
    case 'en_route':
      return const _StatusConfig(
        label: 'En Route',
        fg: AppColors.statusEnRouteFg,
        bg: AppColors.statusEnRouteBg,
        icon: Icons.local_shipping_rounded,
      );
    case 'arrived':
      return const _StatusConfig(
        label: 'Arrived',
        fg: AppColors.statusArrivedFg,
        bg: AppColors.statusArrivedBg,
        icon: Icons.location_on_rounded,
      );
    case 'completed':
      return const _StatusConfig(
        label: 'Completed',
        fg: AppColors.statusCompletedFg,
        bg: AppColors.statusCompletedBg,
        icon: Icons.check_circle_rounded,
      );
    case 'cancelled':
      return const _StatusConfig(
        label: 'Cancelled',
        fg: AppColors.statusCancelledFg,
        bg: AppColors.statusCancelledBg,
        icon: Icons.cancel_rounded,
      );
    default:
      return _StatusConfig(
        label: raw,
        fg: AppColors.textSecondary,
        bg: AppColors.border,
        icon: Icons.circle_outlined,
      );
  }
}
