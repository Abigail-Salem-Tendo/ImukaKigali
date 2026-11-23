// Owner: Member 4
import 'package:flutter/material.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/core/widgets/widgets.dart';
import 'package:imuka_kigali/domain/entities/move_request.dart';
import 'package:imuka_kigali/presentation/screens/driver_jobs/open_job_format.dart';
import 'package:imuka_kigali/presentation/screens/job_logs/job_log_format.dart';

class OpenJobCard extends StatelessWidget {
  const OpenJobCard({
    super.key,
    required this.job,
    required this.isAccepting,
    required this.onAccept,
  });

  final MoveRequest job;

  /// True only on the card whose Accept button was tapped.
  final bool isAccepting;

  /// Null while any job is being accepted, so every button is disabled.
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(job: job),
          const SizedBox(height: AppSpacing.md),
          _RouteBlock(pickup: job.pickupLocation, dropoff: job.dropoffLocation),
          const SizedBox(height: AppSpacing.md),
          _ItemChip(description: job.itemDescription),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Accept ${formatRwf(job.proposedAmount)}',
            isLoading: isAccepting,
            onPressed: onAccept,
          ),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.job});

  final MoveRequest job;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DISPATCH ${dispatchNumber(job.id)}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                formatRwf(job.proposedAmount),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        StatusChip(
          label: postedAgoLabel(job.createdAt, DateTime.now()),
          tone: StatusTone.warning,
          icon: Icons.schedule,
        ),
      ],
    );
  }
}

class _RouteBlock extends StatelessWidget {
  const _RouteBlock({required this.pickup, required this.dropoff});

  final String pickup;
  final String dropoff;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RouteStop(label: 'PICKUP', area: pickup, dotColor: scheme.primary),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          _RouteStop(
            label: 'DESTINATION',
            area: dropoff,
            dotColor: scheme.secondary,
          ),
        ],
      ),
    );
  }
}

class _RouteStop extends StatelessWidget {
  const _RouteStop({
    required this.label,
    required this.area,
    required this.dotColor,
  });

  final String label;
  final String area;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Container(
            width: AppSpacing.sm,
            height: AppSpacing.sm,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                area,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemChip extends StatelessWidget {
  const _ItemChip({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: AppSpacing.md,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
