import 'package:flutter/material.dart';
import 'package:everroute/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// Visual tone for [AssignmentCardActionButton] (matches brand primary / accent).
enum AssignmentCardActionTone { primary, accent }

/// Compact filled CTA for use inside assignment list cards (family link, etc.).
///
/// Uses a reduced height and label size so dense card layouts stay readable.
class AssignmentCardActionButton extends StatelessWidget {
  const AssignmentCardActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.tone = AssignmentCardActionTone.accent,
  });

  static const double _height = 40;
  static const double _iconSize = 16;
  static const double _busySize = 18;

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool busy;
  final AssignmentCardActionTone tone;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? effective = busy ? null : onPressed;
    final labelStyle = GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );

    final ButtonStyle base = FilledButton.styleFrom(
      minimumSize: const Size(0, _height),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      textStyle: labelStyle,
      iconSize: _iconSize,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    final ButtonStyle styled = switch (tone) {
      AssignmentCardActionTone.primary => base.copyWith(
        backgroundColor: const WidgetStatePropertyAll(AppColors.primary),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
      ),
      AssignmentCardActionTone.accent => base.copyWith(
        backgroundColor: const WidgetStatePropertyAll(AppColors.accent),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
      ),
    };

    final Widget child = busy
        ? const SizedBox(
            width: _busySize,
            height: _busySize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Text(label);

    final Widget button = busy
        ? FilledButton(onPressed: null, style: styled, child: child)
        : icon == null
        ? FilledButton(onPressed: effective, style: styled, child: child)
        : FilledButton.icon(
            onPressed: effective,
            style: styled,
            icon: Icon(icon, size: _iconSize),
            label: child,
          );

    return SizedBox(width: double.infinity, height: _height, child: button);
  }
}
