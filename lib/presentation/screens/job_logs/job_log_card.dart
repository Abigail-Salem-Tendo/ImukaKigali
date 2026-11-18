// Owner: Member 4
import 'package:flutter/material.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/core/widgets/widgets.dart';
import 'package:imuka_kigali/domain/entities/move_request.dart';
import 'package:imuka_kigali/presentation/screens/job_logs/job_log_format.dart';

class JobLogCard extends StatelessWidget {
  const JobLogCard({
    super.key,
    required this.job,
    required this.clientName,
    this.onOpenDelivery,
  });

  final MoveRequest job;
  final String clientName;

  /// Only set for accepted jobs, so the card is tappable only when there
  /// is a delivery to go back to.
  final VoidCallback? onOpenDelivery;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onOpenDelivery,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(job: job),
          const SizedBox(height: AppSpacing.md),
          _RouteRow(pickup: job.pickupLocation, dropoff: job.dropoffLocation),
          const SizedBox(height: AppSpacing.md),
          _ClientRow(clientName: clientName, status: job.status),
          if (onOpenDelivery != null) ...[
            const SizedBox(height: AppSpacing.sm),
            const _OpenDeliveryHint(),
          ],
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
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    dispatchNumber(job.id),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  StatusChip(
                    label: jobTimeLabel(
                      job.createdAt,
                      DateTime.now(),
                    ).toUpperCase(),
                    tone: StatusTone.info,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                job.itemDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          formatRwf(job.proposedAmount),
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({required this.pickup, required this.dropoff});

  final String pickup;
  final String dropoff;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'From $pickup to $dropoff',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          children: [
            _Dot(color: scheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Flexible(child: _AreaName(pickup)),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.arrow_forward,
              size: AppSpacing.md,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            _Dot(color: scheme.secondary),
            const SizedBox(width: AppSpacing.sm),
            Flexible(child: _AreaName(dropoff)),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.sm,
      height: AppSpacing.sm,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _AreaName extends StatelessWidget {
  const _AreaName(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _ClientRow extends StatelessWidget {
  const _ClientRow({required this.clientName, required this.status});

  final String clientName;
  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          Icons.person_outline,
          size: AppSpacing.iconSm,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            clientName.isEmpty ? 'Client' : clientName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        StatusChip.request(status),
      ],
    );
  }
}

class _OpenDeliveryHint extends StatelessWidget {
  const _OpenDeliveryHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Continue delivery',
          style: theme.textTheme.labelLarge?.copyWith(color: color),
        ),
        const SizedBox(width: AppSpacing.xs),
        Icon(Icons.arrow_forward, size: AppSpacing.md, color: color),
      ],
    );
  }
}
