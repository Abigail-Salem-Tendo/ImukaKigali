import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/core/widgets/widgets.dart';
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
          AppButton.text(
            label: 'Keep waiting',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          AppButton.danger(
            label: 'Cancel request',
            expand: false,
            onPressed: () => Navigator.of(dialogContext).pop(true),
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
              showAppSnackBar(context, state.error!, type: SnackBarType.error),
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
                if (state.status == FindingDriverStatus.failure) {
                  return EmptyState.error(
                    message: state.error,
                    onRetry: () => context.read<FindingDriverBloc>().add(
                      const FindingDriverStarted(),
                    ),
                    secondaryActionLabel: 'Back to start',
                    onSecondaryAction: () => context.go(AppRoutes.whereFromTo),
                  );
                }
                final request = state.request;
                if (request == null) {
                  return const LoadingView();
                }
                final theme = Theme.of(context);
                return LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - AppSpacing.md * 2,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              const PulseAnimation(),
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                'Finding your driver',
                                style: theme.textTheme.headlineSmall,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'The first available driver will take your job.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _TripSummary(request: request),
                              const SizedBox(height: AppSpacing.md),
                              AppButton.danger(
                                label: 'Cancel request',
                                icon: Icons.close,
                                isLoading: state.cancelling,
                                onPressed: () => _confirmCancel(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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

  String get _vehicle {
    final type = request.vehicleType;
    if (type.isEmpty) return '';
    return type[0].toUpperCase() + type.substring(1);
  }

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
