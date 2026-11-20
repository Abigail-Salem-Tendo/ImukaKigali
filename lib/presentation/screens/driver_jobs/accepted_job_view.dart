// Owner: Member 4
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';
import 'package:imuka_kigali/core/theme/app_colors.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/core/widgets/widgets.dart';
import 'package:imuka_kigali/domain/entities/app_user.dart';
import 'package:imuka_kigali/domain/entities/move_request.dart';
import 'package:imuka_kigali/presentation/screens/job_logs/job_log_format.dart';

class AcceptedJobView extends StatelessWidget {
  const AcceptedJobView({super.key, required this.job, required this.client});

  final MoveRequest job;
  final AppUser? client;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        _AcceptedSummary(job: job),
        const SizedBox(height: AppSpacing.md),
        _ClientContact(client: client),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Go to delivery',
          trailingIcon: Icons.arrow_forward,
          onPressed: () => context.push(AppRoutes.deliveryPath(job.id)),
        ),
      ],
    );
  }
}

class _AcceptedSummary extends StatelessWidget {
  const _AcceptedSummary({required this.job});

  final MoveRequest job;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      highlighted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: AppSpacing.iconMd,
                color: AppColors.success,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Job accepted',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${dispatchNumber(job.id)}  •  ${formatRwf(job.proposedAmount)}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${job.pickupLocation} → ${job.dropoffLocation}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            job.itemDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientContact extends StatelessWidget {
  const _ClientContact({required this.client});

  final AppUser? client;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final client = this.client;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CLIENT',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (client == null)
            Text(
              'The client\'s contact could not be loaded right now.',
              style: theme.textTheme.bodyMedium,
            )
          else ...[
            _ContactRow(icon: Icons.person_outline, text: client.fullName),
            const SizedBox(height: AppSpacing.sm),
            _ContactRow(icon: Icons.phone_outlined, text: client.phone),
          ],
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: AppSpacing.iconSm,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: SelectableText(text, style: theme.textTheme.titleMedium),
        ),
      ],
    );
  }
}
