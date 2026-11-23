// Owner: Member 4
import 'package:flutter/material.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/core/widgets/widgets.dart';

class DriverStatTile extends StatelessWidget {
  const DriverStatTile({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.caption,
  });

  final String label;
  final IconData icon;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(icon, size: AppSpacing.iconSm, color: scheme.primary),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            caption,
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.primary),
          ),
        ],
      ),
    );
  }
}
