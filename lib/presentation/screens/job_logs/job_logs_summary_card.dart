// Owner: Member 4
import 'package:flutter/material.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/presentation/screens/job_logs/job_log_format.dart';
import 'package:imuka_kigali/presentation/screens/job_logs/job_logs_bloc.dart';

class JobLogsSummaryCard extends StatelessWidget {
  const JobLogsSummaryCard({
    super.key,
    required this.period,
    required this.totalEarnings,
    required this.completedCount,
    required this.inProgressCount,
  });

  final JobLogsPeriod period;
  final double totalEarnings;
  final int completedCount;
  final int inProgressCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onCard = theme.colorScheme.onInverseSurface;

    return Container(
      padding: AppSpacing.cardInsets,
      decoration: BoxDecoration(
        color: theme.colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(color: onCard),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            formatRwf(totalEarnings),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: onCard,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  icon: Icons.local_shipping_outlined,
                  label: 'Completed',
                  value: _moves(completedCount),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SummaryTile(
                  icon: Icons.autorenew,
                  label: 'In progress',
                  value: _moves(inProgressCount),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _title => switch (period) {
    JobLogsPeriod.allTrips => 'Total lifetime gross',
    JobLogsPeriod.thisWeek => 'Gross this week',
    JobLogsPeriod.thisMonth => 'Gross this month',
  };

  String _moves(int count) => count == 1 ? '1 Move' : '$count Moves';
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onCard = theme.colorScheme.onInverseSurface;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
      decoration: BoxDecoration(
        color: onCard.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppSpacing.md, color: onCard),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: onCard),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: onCard,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
