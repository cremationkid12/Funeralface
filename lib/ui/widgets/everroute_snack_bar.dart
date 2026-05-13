import 'package:flutter/material.dart';
import 'package:everroute/core/theme/app_theme.dart';

/// Visual variants for [EverrouteSnackBar].
enum EverrouteSnackBarVariant { success, error, info }

abstract final class EverrouteSnackBar {
  /// Core renderer. Prefer the variant-specific helpers
  /// ([success], [error], [info]) unless you need full customisation.
  static void show({
    required BuildContext context,
    required String message,
    EverrouteSnackBarVariant variant = EverrouteSnackBarVariant.info,
    Duration? duration,
    SnackBarAction? action,
    Color? backgroundColor,
    Color textColor = Colors.white,
    IconData? icon,
    double elevation = 6,
    EdgeInsetsGeometry margin = const EdgeInsets.fromLTRB(16, 0, 16, 16),
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),
    ShapeBorder shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  }) {
    final config = _configFor(variant);
    final messenger = ScaffoldMessenger.of(context);
    // Drop any currently-visible snack bar so rapid calls don't queue up.
    messenger.hideCurrentSnackBar();

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon ?? config.icon, color: textColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      duration: duration ?? config.duration,
      backgroundColor: backgroundColor ?? config.backgroundColor,
      elevation: elevation,
      margin: margin,
      padding: padding,
      shape: shape,
      action: action,
      behavior: SnackBarBehavior.floating,
    );

    messenger.showSnackBar(snackBar);
  }

  /// Green success toast — use for confirmations of completed actions.
  static void success(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration? duration,
  }) {
    show(
      context: context,
      message: message,
      variant: EverrouteSnackBarVariant.success,
      action: action,
      duration: duration,
    );
  }

  /// Red error toast — use for failures, API errors, validation problems.
  static void error(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration? duration,
  }) {
    show(
      context: context,
      message: message,
      variant: EverrouteSnackBarVariant.error,
      action: action,
      duration: duration,
    );
  }

  /// Neutral dark toast — use for informational/transient notices.
  static void info(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration? duration,
  }) {
    show(
      context: context,
      message: message,
      variant: EverrouteSnackBarVariant.info,
      action: action,
      duration: duration,
    );
  }
}

class _VariantConfig {
  const _VariantConfig({
    required this.backgroundColor,
    required this.icon,
    required this.duration,
  });

  final Color backgroundColor;
  final IconData icon;
  final Duration duration;
}

_VariantConfig _configFor(EverrouteSnackBarVariant variant) {
  switch (variant) {
    case EverrouteSnackBarVariant.success:
      return const _VariantConfig(
        backgroundColor: AppColors.primary,
        icon: Icons.check_circle_rounded,
        duration: Duration(seconds: 2),
      );
    case EverrouteSnackBarVariant.error:
      return const _VariantConfig(
        backgroundColor: Color(0xFFC62828),
        icon: Icons.error_rounded,
        duration: Duration(seconds: 3),
      );
    case EverrouteSnackBarVariant.info:
      return const _VariantConfig(
        backgroundColor: AppColors.textPrimary,
        icon: Icons.info_rounded,
        duration: Duration(seconds: 2),
      );
  }
}
