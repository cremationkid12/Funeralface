import 'package:flutter/material.dart';
import 'package:funeralface_mobile/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class RoleChip extends StatelessWidget {
  const RoleChip({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final isAdmin = role.toLowerCase() == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin ? AppColors.statusEnRouteBg : AppColors.accentSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role[0].toUpperCase() + role.substring(1),
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isAdmin ? AppColors.statusEnRouteFg : AppColors.accent,
        ),
      ),
    );
  }
}
