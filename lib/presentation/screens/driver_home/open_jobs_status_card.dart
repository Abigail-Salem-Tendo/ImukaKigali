// Owner: Member 4
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/core/widgets/widgets.dart';

class OpenJobsStatusCard extends StatelessWidget {
  const OpenJobsStatusCard({
    super.key,
    required this.openJobCount,
    required this.vehicleLabel,
    required this.district,
  });

  final int openJobCount;
  final String vehicleLabel;
  final String district;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final jobs = openJobCount == 1 ? '1 open job' : '$openJobCount open jobs';

    return AppCard(
      onTap: () => context.go(AppRoutes.driverJobs),
      child: Row(
        children: [
          CircleAvatar(
            radius: AppSpacing.lg,
            backgroundColor: scheme.primaryContainer,
            child: Icon(
              Icons.local_shipping_outlined,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$jobs for your $vehicleLabel',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  district.isEmpty ? 'Kigali' : '$district District Hub',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
