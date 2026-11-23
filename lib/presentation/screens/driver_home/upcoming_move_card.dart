// Owner: Member 4
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/core/widgets/widgets.dart';
import 'package:imuka_kigali/domain/entities/move_request.dart';
import 'package:imuka_kigali/presentation/screens/driver_jobs/open_job_format.dart';
import 'package:imuka_kigali/presentation/screens/job_logs/job_log_format.dart';

class UpcomingMoveCard extends StatelessWidget {
  const UpcomingMoveCard({super.key, required this.job});

  final MoveRequest job;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      onTap: () => context.push(AppRoutes.deliveryPath(job.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StatusChip(
                    label: postedAgoLabel(job.createdAt, DateTime.now()),
                    tone: StatusTone.info,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                formatRwf(job.proposedAmount),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: AppSpacing.iconSm,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${job.pickupLocation} → ${job.dropoffLocation}',
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      job.itemDescription,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ],
      ),
    );
  }
}
