import 'package:flutter/material.dart';
import 'package:everroute/core/theme/app_theme.dart';

/// Square bordered back control used on detail and auth flow screens.
class EverrouteBackButton extends StatelessWidget {
  const EverrouteBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed ?? () => Navigator.of(context).pop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
