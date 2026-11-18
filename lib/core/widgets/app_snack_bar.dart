// Owner: Member 1
// Shared helper: showAppSnackBar. The one way to show a short message.
// Every failure in a BlocListener should call this (no silent failures).
//
//   showAppSnackBar(context, state.error ?? 'Something went wrong', type: SnackBarType.error);
//   showAppSnackBar(context, 'Job accepted', type: SnackBarType.success);
//   showAppSnackBar(context, 'Request cancelled', actionLabel: 'Undo', onAction: ...);
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum SnackBarType { info, success, error }

void showAppSnackBar(
  BuildContext context,
  String message, {
  SnackBarType type = SnackBarType.info,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  final scheme = Theme.of(context).colorScheme;
  final (background, foreground, icon) = switch (type) {
    SnackBarType.success => (
      AppColors.success,
      scheme.onPrimary,
      Icons.check_circle_outline,
    ),
    SnackBarType.error => (scheme.error, scheme.onError, Icons.error_outline),
    SnackBarType.info => (
      scheme.inverseSurface,
      scheme.onInverseSurface,
      Icons.info_outline,
    ),
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar() // never stack several messages
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: AppSpacing.screenPadding,
        backgroundColor: background,
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
        ),
        content: Row(
          children: [
            Icon(icon, color: foreground, size: AppSpacing.iconSm),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(message, style: TextStyle(color: foreground)),
            ),
          ],
        ),
        action: actionLabel == null || onAction == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: foreground,
                onPressed: onAction,
              ),
      ),
    );
}
