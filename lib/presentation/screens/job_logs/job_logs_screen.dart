// Owner: Member 4
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/core/widgets/widgets.dart';
import 'package:imuka_kigali/domain/entities/move_request.dart';
import 'package:imuka_kigali/domain/repositories/auth_repository.dart';
import 'package:imuka_kigali/domain/repositories/driver_job_repository.dart';
import 'package:imuka_kigali/presentation/screens/job_logs/job_log_card.dart';
import 'package:imuka_kigali/presentation/screens/job_logs/job_logs_bloc.dart';
import 'package:imuka_kigali/presentation/screens/job_logs/job_logs_period_tabs.dart';
import 'package:imuka_kigali/presentation/screens/job_logs/job_logs_summary_card.dart';
import 'package:imuka_kigali/presentation/screens/login/auth_bloc.dart';

class JobLogsScreen extends StatelessWidget {
  const JobLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => JobLogsBloc(
        ctx.read<DriverJobRepository>(),
        ctx.read<AuthRepository>(),
      )..add(JobLogsRequested(_signedInDriverId(ctx))),
      child: BlocListener<JobLogsBloc, JobLogsState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == JobLogsStatus.failure) {
            showAppSnackBar(
              context,
              state.error ?? 'Could not load your jobs',
              type: SnackBarType.error,
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(centerTitle: false, title: const _JobLogsTitle()),
          bottomNavigationBar: const DriverBottomNav(
            current: DriverTab.jobLogs,
          ),
          body: SafeArea(
            child: BlocBuilder<JobLogsBloc, JobLogsState>(
              builder: (context, state) => switch (state.status) {
                JobLogsStatus.initial ||
                JobLogsStatus.loading => const LoadingView.skeleton(),
                JobLogsStatus.failure => EmptyState.error(
                  message: state.error,
                  onRetry: () => context.read<JobLogsBloc>().add(
                    JobLogsRequested(_signedInDriverId(context)),
                  ),
                ),
                JobLogsStatus.success =>
                  state.allJobs.isEmpty
                      ? const _NoJobsYet()
                      : _JobLogsList(state: state),
              },
            ),
          ),
        ),
      ),
    );
  }
}

String _signedInDriverId(BuildContext context) =>
    context.read<AuthBloc>().state.user?.uid ?? '';

class _JobLogsTitle extends StatelessWidget {
  const _JobLogsTitle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'IMUKA KIGALI',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          'Job History',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _NoJobsYet extends StatelessWidget {
  const _NoJobsYet();

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.work_outline,
      title: 'No jobs yet',
      message: 'Jobs you accept will show up here.',
      actionLabel: 'Find jobs',
      onAction: () => context.go(AppRoutes.driverJobs),
    );
  }
}

class _JobLogsList extends StatelessWidget {
  const _JobLogsList({required this.state});

  final JobLogsState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        JobLogsPeriodTabs(
          selected: state.period,
          onChanged: (period) =>
              context.read<JobLogsBloc>().add(JobLogsPeriodChanged(period)),
        ),
        const SizedBox(height: AppSpacing.md),
        JobLogsSummaryCard(
          period: state.period,
          totalEarnings: state.totalEarnings,
          completedCount: state.completedCount,
          inProgressCount: state.inProgressCount,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Recent dispatch jobs',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.visibleJobs.isEmpty)
          const EmptyState(
            icon: Icons.event_busy_outlined,
            title: 'No jobs in this period',
            message: 'Pick All Trips to see every job.',
          ),
        for (final job in state.visibleJobs) ...[
          _jobCard(context, job),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  Widget _jobCard(BuildContext context, MoveRequest job) {
    return JobLogCard(
      job: job,
      clientName: state.clientNames[job.clientId] ?? '',
      onOpenDelivery: job.status == RequestStatus.accepted
          ? () => context.push(AppRoutes.deliveryPath(job.id))
          : null,
    );
  }
}
