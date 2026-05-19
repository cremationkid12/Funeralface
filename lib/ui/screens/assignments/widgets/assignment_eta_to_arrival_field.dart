import 'package:flutter/material.dart';
import 'package:everroute/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// Time picker UI for "ETA to Arrival" on create/edit assignment flows.
class AssignmentEtaToArrivalField extends StatelessWidget {
  const AssignmentEtaToArrivalField({
    super.key,
    required this.etaTime,
    required this.enabled,
    required this.onPick,
    required this.onClear,
    this.useOutlinedBorder = false,
  });

  final TimeOfDay? etaTime;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final bool useOutlinedBorder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ETA to Arrival',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: enabled ? onPick : null,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: 'Select time',
              border: useOutlinedBorder ? const OutlineInputBorder() : null,
              enabled: enabled,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 12, right: 8),
                child: Icon(
                  Icons.schedule_outlined,
                  color: AppColors.accent,
                  size: 18,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              suffixIcon: etaTime == null
                  ? null
                  : IconButton(
                      onPressed: enabled ? onClear : null,
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
            ),
            child: Text(
              etaTime == null ? 'Select time' : etaTime!.format(context),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: etaTime == null
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
