// Owner: Member 4
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/core/widgets/widgets.dart';
import 'package:imuka_kigali/domain/entities/move_request.dart';
// Member 2's formatRwf(int) clashes with mine in job_log_format.dart, so it
// is hidden until the group agrees on one shared formatRwf.
import 'package:imuka_kigali/domain/entities/vehicle_class.dart';
import 'package:imuka_kigali/domain/repositories/driver_job_repository.dart';
import 'package:imuka_kigali/domain/repositories/vehicle_repository.dart';
import 'package:imuka_kigali/presentation/screens/driver_home/driver_home_bloc.dart';
import 'package:imuka_kigali/presentation/screens/driver_home/driver_stat_tile.dart';
import 'package:imuka_kigali/presentation/screens/driver_home/no_vehicle_view.dart';
import 'package:imuka_kigali/presentation/screens/driver_home/open_jobs_status_card.dart';
import 'package:imuka_kigali/presentation/screens/driver_home/upcoming_move_card.dart';
import 'package:imuka_kigali/presentation/screens/driver_home/vehicle_profile_tile.dart';
import 'package:imuka_kigali/presentation/screens/job_logs/job_log_format.dart';
import 'package:imuka_kigali/presentation/screens/login/auth_bloc.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => DriverHomeBloc(
        ctx.read<DriverJobRepository>(),
        ctx.read<VehicleRepository>(),
      )..add(DriverHomeStarted(_signedInDriverId(ctx))),
      child: BlocListener<DriverHomeBloc, DriverHomeState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == DriverHomeStatus.failure) {
            showAppSnackBar(
              context,
              state.error ?? 'Could not load your dashboard',
              type: SnackBarType.error,
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            centerTitle: false,
            title: const _HomeTitle(),
            actions: [
              IconButton(
                tooltip: 'Driver profile',
                icon: const Icon(Icons.person_outline),
                onPressed: () => context.push(AppRoutes.driverProfile),
              ),
            ],
          ),
          bottomNavigationBar: const DriverBottomNav(current: DriverTab.home),
          body: SafeArea(
            child: BlocBuilder<DriverHomeBloc, DriverHomeState>(
              builder: (context, state) => switch (state.status) {
                DriverHomeStatus.initial ||
                DriverHomeStatus.loading => const LoadingView.skeleton(),
                DriverHomeStatus.failure => EmptyState.error(
                  message: state.error,
                  onRetry: () => context.read<DriverHomeBloc>().add(
                    DriverHomeStarted(_signedInDriverId(context)),
                  ),
                ),
                DriverHomeStatus.noVehicle => const NoVehicleView(),
                DriverHomeStatus.success => _HomeContent(state: state),
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

class _HomeTitle extends StatelessWidget {
  const _HomeTitle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Imuka Kigali',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          'DRIVER FLEET',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.state});

  final DriverHomeState state;

  @override
  Widget build(BuildContext context) {
    final vehicle = state.vehicle!;
    final district = context.select(
      (AuthBloc bloc) => bloc.state.user?.district ?? '',
    );
    final completed = state.completedCount;

    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        OpenJobsStatusCard(
          openJobCount: state.openJobCount,
          vehicleLabel: VehicleClasses.of(vehicle.vehicleType).shortLabel,
          district: district,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: DriverStatTile(
                label: 'TOTAL EARNINGS',
                icon: Icons.payments_outlined,
                value: formatRwf(state.totalEarnings),
                caption: completed == 1
                    ? 'from 1 move'
                    : 'from $completed moves',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: DriverStatTile(
                label: 'JOBS DONE',
                icon: Icons.task_alt,
                value: '$completed',
                caption: 'completed moves',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _UpcomingMoves(acceptedJobs: state.acceptedJobs),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Driver Quick Tools',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        VehicleProfileTile(vehicle: vehicle),
      ],
    );
  }
}

class _UpcomingMoves extends StatelessWidget {
  const _UpcomingMoves({required this.acceptedJobs});

  final List<MoveRequest> acceptedJobs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Upcoming accepted moves',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            StatusChip(
              label: '${acceptedJobs.length} accepted',
              tone: StatusTone.brand,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (acceptedJobs.isEmpty)
          AppCard(
            child: Text(
              'No accepted moves yet. Tap the card above to find one.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final job in acceptedJobs) ...[
          UpcomingMoveCard(job: job),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
