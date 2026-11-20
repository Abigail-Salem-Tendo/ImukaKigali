// Owner: Member 1
// Shared widget: AppCard. The rounded white card with a light border used on
// every screen (job cards, trip summaries, profile sections).
//
//   AppCard(child: ...)
//   AppCard(onTap: () => context.push(...), child: ...)   // whole card is tappable
//   AppCard(highlighted: true, child: ...)                  // light brand tint, e.g. "Gasabo District Hub"
import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.highlighted = false,
    this.padding = AppSpacing.cardInsets,
    this.margin = EdgeInsets.zero,
  });

  final Widget child;

  /// Makes the whole card tappable with a ripple.
  final VoidCallback? onTap;

  /// Light brand-coloured background and border instead of white.
  final bool highlighted;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = Padding(padding: padding, child: child);

    return Card(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      color: highlighted ? scheme.primary.withValues(alpha: 0.08) : null,
      shape: highlighted
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              side: BorderSide(
                color: scheme.primary.withValues(alpha: 0.2),
                width: AppSpacing.borderWidth,
              ),
            )
          : null, // null = the card style from AppTheme
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}
