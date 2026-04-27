import 'package:flutter/material.dart';
import 'package:everroute/core/theme/app_theme.dart';
import 'package:everroute/services/assignments_services.dart';
import 'package:everroute/ui/widgets/app_status_chip.dart';
import 'package:google_fonts/google_fonts.dart';

class AssignmentCard extends StatelessWidget {
  const AssignmentCard({
    super.key,
    required this.data,
    required this.isExpanded,
    required this.submitting,
    this.onToggle,
    required this.onStatusChange,
    this.onTap,
  });

  final Map<String, dynamic> data;
  final bool isExpanded;
  final bool submitting;
  final VoidCallback? onToggle;
  final ValueChanged<String> onStatusChange;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final name = data['decedent_name']?.toString() ?? '—';
    final address = data['pickup_address']?.toString() ?? '';
    final contactName = data['contact_name']?.toString() ?? '';
    final contactPhone = data['contact_phone']?.toString() ?? '';
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                                  _AssignedStaffFallback(initials: initials),
                            ),
                          )
                        : _AssignedStaffFallback(initials: initials),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (address.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 13,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  address,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w500,
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
                  GestureDetector(
                    onTap: onToggle,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: AnimatedRotation(
                        turns: isExpanded ? 0 : 0.5,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.keyboard_arrow_up_rounded,
                          color: AppColors.accent,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isExpanded) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.statusEnRouteBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.phone_outlined,
                      size: 14,
                      color: AppColors.statusEnRouteFg,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Contact',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      [
                        if (contactName.isNotEmpty) contactName,
                        if (contactPhone.isNotEmpty) contactPhone,
                      ].join(' '),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: AssignmentsServices.statuses.map((s) {
                    final isCurrent = s == status;
                    return GestureDetector(
                      onTap: submitting || isCurrent
                          ? null
                          : () => onStatusChange(s),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AppStatusChip(status: s),
                          if (isCurrent)
                            Positioned(
                              top: -4,
                              left: -4,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ] else ...[
              if (contactName.isNotEmpty || contactPhone.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.statusEnRouteBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 14,
                        color: AppColors.statusEnRouteFg,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Contact',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        [
                          if (contactName.isNotEmpty) contactName,
                          if (contactPhone.isNotEmpty) contactPhone,
                        ].join(' '),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AssignedStaffFallback extends StatelessWidget {
  const _AssignedStaffFallback({required this.initials});

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
