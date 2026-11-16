import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/domain/entities/move_request.dart';
import 'package:imuka_kigali/domain/repositories/request_repository.dart';
import 'package:imuka_kigali/presentation/screens/finding_driver/finding_driver_bloc.dart';
import 'package:imuka_kigali/presentation/screens/finding_driver/pulse_animation.dart';

/// Creates its own bloc. Route: AppRoutes.findingDriver.
class FindingDriverScreen extends StatelessWidget {
  const FindingDriverScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          FindingDriverBloc(context.read<RequestRepository>(), requestId)
            ..add(const FindingDriverStarted()),
      child: _FindingDriverView(requestId: requestId),
    );
  }
}

class _FindingDriverView extends StatelessWidget {
  const _FindingDriverView({required this.requestId});

  final String requestId;

  Future<void> _confirmCancel(BuildContext context) async {
    final bloc = context.read<FindingDriverBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this request?'),
        content: const Text('We will stop looking for a driver.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep waiting'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel request'),
          ),
        ],
      ),
    );
    if (confirmed == true) bloc.add(const CancelRequested());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<FindingDriverBloc, FindingDriverState>(
          listenWhen: (prev, curr) => prev.status != curr.status,
          listener: (context, state) {
            if (state.status == FindingDriverStatus.accepted) {
              context.go(AppRoutes.driverContactPath(requestId));
            } else if (state.status == FindingDriverStatus.cancelled) {
              context.go(AppRoutes.whereFromTo);
            }
          },
        ),
        BlocListener<FindingDriverBloc, FindingDriverState>(
          listenWhen: (prev, curr) =>
              curr.error != null && prev.error != curr.error,
          listener: (context, state) =>
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.error!))),
        ),
      ],
      // The client must cancel explicitly instead of backing out.
      child: PopScope(
        canPop: false,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Finding your driver'),
            automaticallyImplyLeading: false,
          ),
          body: SafeArea(
            child: BlocBuilder<FindingDriverBloc, FindingDriverState>(
              builder: (context, state) {
                final request = state.request;
                if (state.status == FindingDriverStatus.failure &&
                    request == null) {
                  return Center(
                    child: Text(state.error ?? 'Something went wrong'),
                  );
                }
                if (request == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      const Spacer(),
                      const PulseAnimation(),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Finding your driver',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'The first available driver will take your job.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      _TripSummary(request: request),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        height: AppSpacing.buttonHeight,
                        child: OutlinedButton(
                          onPressed: state.cancelling
                              ? null
                              : () => _confirmCancel(context),
                          child: state.cancelling
                              ? const SizedBox.square(
                                  dimension: AppSpacing.lg,
                                  child: CircularProgressIndicator(),
                                )
                              : const Text('Cancel request'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TripSummary extends StatelessWidget {
  const _TripSummary({required this.request});

  final MoveRequest request;

  String get _vehicle =>
      request.vehicleType[0].toUpperCase() + request.vehicleType.substring(1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${request.pickupLocation} to ${request.dropoffLocation}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(request.itemDescription),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_vehicle, style: theme.textTheme.bodyMedium),
                Text(
                  '${request.proposedAmount.toStringAsFixed(0)} RWF',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
