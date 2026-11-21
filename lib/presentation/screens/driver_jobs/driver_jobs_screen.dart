// Owner: Member 4
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/core/widgets/widgets.dart';
import 'package:imuka_kigali/domain/repositories/auth_repository.dart';
import 'package:imuka_kigali/domain/repositories/driver_job_repository.dart';
import 'package:imuka_kigali/domain/repositories/vehicle_repository.dart';
import 'package:imuka_kigali/presentation/screens/driver_home/no_vehicle_view.dart';
import 'package:imuka_kigali/presentation/screens/driver_jobs/accept_job_bloc.dart';
import 'package:imuka_kigali/presentation/screens/driver_jobs/accepted_job_view.dart';
import 'package:imuka_kigali/presentation/screens/driver_jobs/driver_jobs_header.dart';
import 'package:imuka_kigali/presentation/screens/driver_jobs/open_job_card.dart';
import 'package:imuka_kigali/presentation/screens/driver_jobs/open_jobs_bloc.dart';
import 'package:imuka_kigali/presentation/screens/login/auth_bloc.dart';

class DriverJobsScreen extends StatelessWidget {
  const DriverJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (ctx) => OpenJobsBloc(
            ctx.read<DriverJobRepository>(),
            ctx.read<VehicleRepository>(),
          )..add(OpenJobsStarted(_signedInDriverId(ctx))),
        ),
        BlocProvider(
          create: (ctx) => AcceptJobBloc(
            ctx.read<DriverJobRepository>(),
            ctx.read<AuthRepository>(),
          ),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<OpenJobsBloc, OpenJobsState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              if (state.status == OpenJobsStatus.failure) {
                showAppSnackBar(
                  context,
                  state.error ?? 'Could not load open jobs',
                  type: SnackBarType.error,
                );
              }
            },
          ),
          BlocListener<AcceptJobBloc, AcceptJobState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              if (state.status == AcceptJobStatus.failure) {
                showAppSnackBar(
                  context,
                  state.error ?? 'Could not accept the job',
                  type: SnackBarType.error,
                );
              }
              if (state.status == AcceptJobStatus.success) {
                showAppSnackBar(
                  context,
                  'Job accepted',
                  type: SnackBarType.success,
                );
              }
            },
          ),
        ],
        child: Scaffold(
          appBar: AppBar(centerTitle: false, title: const _JobsTitle()),
          bottomNavigationBar: const DriverBottomNav(current: DriverTab.jobs),
          body: SafeArea(
            child: BlocBuilder<AcceptJobBloc, AcceptJobState>(
              builder: (context, acceptState) {
                final acceptedJob = acceptState.acceptedJob;
                if (acceptedJob != null) {
                  return AcceptedJobView(
                    job: acceptedJob,
                    client: acceptState.client,
                  );
                }
                return _OpenJobsBody(acceptState: acceptState);
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

class _JobsTitle extends StatelessWidget {
  const _JobsTitle();

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
          'Jobs',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _OpenJobsBody extends StatelessWidget {
  const _OpenJobsBody({required this.acceptState});

  final AcceptJobState acceptState;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OpenJobsBloc, OpenJobsState>(
      builder: (context, state) => switch (state.status) {
        OpenJobsStatus.initial ||
        OpenJobsStatus.loading => const LoadingView.skeleton(),
        OpenJobsStatus.failure => EmptyState.error(
          message: state.error,
          onRetry: () => context.read<OpenJobsBloc>().add(
            OpenJobsStarted(_signedInDriverId(context)),
          ),
        ),
        OpenJobsStatus.noVehicle => const NoVehicleView(),
        OpenJobsStatus.success => _OpenJobsList(
          state: state,
          acceptState: acceptState,
        ),
      },
    );
  }
}

class _OpenJobsList extends StatelessWidget {
  const _OpenJobsList({required this.state, required this.acceptState});

  final OpenJobsState state;
  final AcceptJobState acceptState;

  @override
  Widget build(BuildContext context) {
    final district = context.select(
      (AuthBloc bloc) => bloc.state.user?.district ?? '',
    );

    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        DriverJobsHeader(district: district, vehicle: state.vehicle!),
        const SizedBox(height: AppSpacing.lg),
        _ListTitle(jobCount: state.jobs.length),
        const SizedBox(height: AppSpacing.md),
        if (state.jobs.isEmpty)
          const EmptyState(
            icon: Icons.local_shipping_outlined,
            title: 'No open jobs right now',
            message: 'New moves for your vehicle will show up here.',
          ),
        for (final job in state.jobs) ...[
          OpenJobCard(
            job: job,
            isAccepting: acceptState.acceptingJobId == job.id,
            onAccept: acceptState.isAccepting
                ? null
                : () => context.read<AcceptJobBloc>().add(JobAccepted(job)),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _ListTitle extends StatelessWidget {
  const _ListTitle({required this.jobCount});

  final int jobCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Available dispatch requests',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        StatusChip(label: '$jobCount', tone: StatusTone.brand),
      ],
    );
  }
}
