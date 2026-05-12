import 'package:flutter/material.dart';
import 'package:everroute/core/theme/app_theme.dart';

/// Standard tap target height used for primary/accent CTAs across the app.
const double _kAppButtonHeight = 52.0;

/// Size of the in-button busy spinner that replaces the label.
const double _kAppButtonBusySize = 20.0;

/// Filled CTA rendered with the brand primary (green) colour.
///
/// Used for the dominant action on a screen, sheet or dialog — for example
/// "Save", "Create", "Send Invite", "Sign out", "Share Link".
///
/// Optionally renders a leading [icon] (matches [FilledButton.icon]) and
/// supports a [busy] state that replaces the label with a small spinner and
/// disables taps.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.expand = true,
    this.height = _kAppButtonHeight,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool busy;

  /// When true (default) the button stretches to fill its parent's width.
  final bool expand;

  /// Fixed button height. Pass `null`-equivalent by overriding with a custom
  /// value if you need a different tap target.
  final double height;

  @override
  Widget build(BuildContext context) {
    return _AppFilledButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      busy: busy,
      expand: expand,
      height: height,
      style: null,
    );
  }
}

/// Filled button rendered with the brand accent (orange) colour.
///
/// Used for secondary actions inside sheets/dialogs ("Cancel") as well as
/// accent CTAs such as "Copy Link" or "Remove Staff Member".
///
/// Has the same API as [AppPrimaryButton]; the only difference is its
/// background/foreground colours.
class AppAccentButton extends StatelessWidget {
  const AppAccentButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.expand = true,
    this.height = _kAppButtonHeight,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool busy;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    return _AppFilledButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      busy: busy,
      expand: expand,
      height: height,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _AppFilledButton extends StatelessWidget {
  const _AppFilledButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.busy,
    required this.expand,
    required this.height,
    required this.style,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool busy;
  final bool expand;
  final double height;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? effectiveOnPressed = busy ? null : onPressed;
    final Widget child = busy ? const _AppButtonSpinner() : Text(label);

    final Widget button = icon == null
        ? FilledButton(
            onPressed: effectiveOnPressed,
            style: style,
            child: child,
          )
        : FilledButton.icon(
            onPressed: effectiveOnPressed,
            style: style,
            icon: Icon(icon),
            label: child,
          );

    return SizedBox(
      width: expand ? double.infinity : null,
      height: height,
      child: button,
    );
  }
}

class _AppButtonSpinner extends StatelessWidget {
  const _AppButtonSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: _kAppButtonBusySize,
      height: _kAppButtonBusySize,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );
  }
}
