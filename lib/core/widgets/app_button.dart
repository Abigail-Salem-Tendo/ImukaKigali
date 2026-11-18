// Owner: Member 1
// Shared widget: AppButton. The five button styles from the Figma design system.
//
//   AppButton(label: 'Post move request', onPressed: ..., trailingIcon: Icons.arrow_forward)
//   AppButton.secondary(label: 'View Driver Profile', icon: Icons.person_outline, onPressed: ...)
//   AppButton.tonal(label: 'Counter-Offer / Bid', onPressed: ...)
//   AppButton.danger(label: 'Cancel Move Request', icon: Icons.close, onPressed: ...)
//   AppButton.text(label: 'View more', onPressed: ...)
//
// Pass onPressed: null to disable it. Set isLoading: true while the bloc is busy
// (shows a spinner and ignores taps, so a request can't be sent twice).
import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

enum AppButtonVariant {
  /// Filled brand colour. The main action on a screen.
  primary,

  /// Outlined. A second, less important action.
  secondary,

  /// Light brand tint. Side actions inside cards (e.g. "Counter-Offer").
  tonal,

  /// Light red tint. Destructive actions (cancel, log out).
  danger,

  /// Plain text link (e.g. "View more", "Forgot password?").
  text,
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = true,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = true,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.tonal({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = true,
  }) : variant = AppButtonVariant.tonal;

  const AppButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = true,
  }) : variant = AppButtonVariant.danger;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = false,
  }) : variant = AppButtonVariant.text;

  final String label;

  /// null = disabled.
  final VoidCallback? onPressed;
  final AppButtonVariant variant;

  /// Icon before the label.
  final IconData? icon;

  /// Icon after the label (e.g. Icons.arrow_forward on "Continue").
  final IconData? trailingIcon;
  final bool isLoading;

  /// true = full width. Set false to put buttons side by side in a Row.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final callback = isLoading ? null : onPressed;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
    );
    final minSize = expand
        ? const Size.fromHeight(AppSpacing.buttonHeight)
        : const Size(0, AppSpacing.buttonHeight);
    const padding = EdgeInsets.symmetric(horizontal: AppSpacing.md);
    final textStyle = Theme.of(context).textTheme.labelLarge
        ?.copyWith(fontWeight: FontWeight.w600);

    final Color foreground = switch (variant) {
      AppButtonVariant.primary => scheme.onPrimary,
      AppButtonVariant.danger => scheme.error,
      _ => scheme.primary,
    };
    final child = _content(foreground);

    final Widget button = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
        onPressed: callback,
        style: ElevatedButton.styleFrom(
          minimumSize: minSize,
          padding: padding,
          shape: shape,
          textStyle: textStyle,
          elevation: 0,
        ),
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: callback,
        style: OutlinedButton.styleFrom(
          minimumSize: minSize,
          padding: padding,
          shape: shape,
          textStyle: textStyle,
        ),
        child: child,
      ),
      AppButtonVariant.tonal => FilledButton(
        onPressed: callback,
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary.withValues(alpha: 0.12),
          foregroundColor: scheme.primary,
          minimumSize: minSize,
          padding: padding,
          shape: shape,
          textStyle: textStyle,
        ),
        child: child,
      ),
      AppButtonVariant.danger => FilledButton(
        onPressed: callback,
        style: FilledButton.styleFrom(
          backgroundColor: scheme.error.withValues(alpha: 0.1),
          foregroundColor: scheme.error,
          minimumSize: minSize,
          padding: padding,
          shape: shape,
          textStyle: textStyle,
        ),
        child: child,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: callback,
        style: TextButton.styleFrom(textStyle: textStyle, shape: shape),
        child: child,
      ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _content(Color foreground) {
    if (isLoading) {
      return SizedBox.square(
        dimension: AppSpacing.iconSm,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: variant == AppButtonVariant.primary ? foreground : null,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppSpacing.iconSm),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(trailingIcon, size: AppSpacing.iconSm),
        ],
      ],
    );
  }
}
