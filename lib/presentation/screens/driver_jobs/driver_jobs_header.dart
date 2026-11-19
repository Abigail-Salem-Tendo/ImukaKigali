// Owner: Member 4
import 'package:flutter/material.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/core/widgets/widgets.dart';
import 'package:imuka_kigali/presentation/screens/driver_jobs/open_job_format.dart';

class DriverJobsHeader extends StatelessWidget {
  const DriverJobsHeader({
    super.key,
    required this.district,
    required this.vehicleType,
  });

  final String district;
  final String vehicleType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      highlighted: true,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.my_location,
              size: AppSpacing.iconMd,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  district.isEmpty ? 'Kigali' : '$district District Hub',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  vehicleTypeLabel(vehicleType),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
