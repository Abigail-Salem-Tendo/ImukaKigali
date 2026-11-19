// Owner: Member 1
// Shared widget: StatusChip. The small pill badges from the Figma
// "Status badges" section.
//
//   StatusChip.request(request.status)        // open / accepted / completed / cancelled
//   StatusChip.payment(payment.status)        // pending / paid
//   StatusChip(label: 'Ready Now', tone: StatusTone.success, icon: Icons.bolt)
//   StatusChip(label: 'Top Rated', tone: StatusTone.brand)
import 'package:flutter/material.dart';

import '../constants/firestore_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum StatusTone {
  /// Green: done, verified, paid.
  success,

  /// Yellow: waiting, pending.
  warning,

  /// Brand colour: in progress.
  info,

  /// Red: cancelled, failed.
  danger,

  /// Grey: plain labels (e.g. "Standard Van").
  neutral,

  /// Solid brand colour with white text (e.g. "Top Rated").
  brand,
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
  });

  /// Chip for a request's status string (RequestStatus.*).
  factory StatusChip.request(String status, {Key? key}) => switch (status) {
    RequestStatus.open => StatusChip(
      key: key,
      label: 'Finding driver',
      tone: StatusTone.warning,
      icon: Icons.schedule,
    ),
    RequestStatus.accepted => StatusChip(
      key: key,
      label: 'Accepted',
      tone: StatusTone.info,
      icon: Icons.local_shipping_outlined,
    ),
    RequestStatus.completed => StatusChip(
      key: key,
      label: 'Completed',
      tone: StatusTone.success,
      icon: Icons.check_circle_outline,
    ),
    RequestStatus.cancelled => StatusChip(
      key: key,
      label: 'Cancelled',
      tone: StatusTone.danger,
      icon: Icons.close,
    ),
    _ => StatusChip(key: key, label: status),
  };

  /// Chip for a payment's status string (PaymentStatus.*).
  factory StatusChip.payment(String status, {Key? key}) => switch (status) {
    PaymentStatus.pending => StatusChip(
      key: key,
      label: 'Pending',
      tone: StatusTone.warning,
      icon: Icons.hourglass_empty,
    ),
    PaymentStatus.paid => StatusChip(
      key: key,
      label: 'Paid',
      tone: StatusTone.success,
      icon: Icons.check,
    ),
    _ => StatusChip(key: key, label: status),
  };

  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (foreground, background) = _colors(theme.colorScheme);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.xl), // pill
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSpacing.md, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// (text colour, background colour) for each tone, all from the theme.
  (Color, Color) _colors(ColorScheme scheme) => switch (tone) {
    StatusTone.success => (
      AppColors.success,
      AppColors.success.withValues(alpha: 0.12),
    ),
    StatusTone.warning => (
      scheme.onSurface,
      scheme.secondary.withValues(alpha: 0.25),
    ),
    StatusTone.info => (scheme.primary, scheme.primary.withValues(alpha: 0.12)),
    StatusTone.danger => (scheme.error, scheme.error.withValues(alpha: 0.12)),
    StatusTone.neutral => (
      scheme.onSurfaceVariant,
      scheme.onSurface.withValues(alpha: 0.06),
    ),
    StatusTone.brand => (scheme.onPrimary, scheme.primary),
  };
}
