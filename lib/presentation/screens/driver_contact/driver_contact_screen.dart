// Owner: Member 5
// Screen: the client's driver has accepted. Shows who they are, their vehicle
// and the fixed price, so the two can agree the details by phone.
// (The Figma screen "Negotiate Driver & Direct Contact"; with no bidding there
// is nothing to negotiate.) Route: AppRoutes.driverContact.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/core/widgets/widgets.dart';
import 'package:imuka_kigali/domain/repositories/auth_repository.dart';
import 'package:imuka_kigali/domain/repositories/request_repository.dart';
import 'package:imuka_kigali/domain/repositories/vehicle_repository.dart';
import 'package:imuka_kigali/presentation/screens/driver_contact/driver_contact_bloc.dart';
import 'package:imuka_kigali/presentation/screens/driver_contact/driver_contact_sections.dart';

/// Creates its own bloc.
class DriverContactScreen extends StatelessWidget {
  const DriverContactScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DriverContactBloc(
        context.read<RequestRepository>(),
        context.read<AuthRepository>(),
        context.read<VehicleRepository>(),
        requestId,
      )..add(const DriverContactStarted()),
      child: _DriverContactView(requestId: requestId),
    );
  }
}

class _DriverContactView extends StatelessWidget {
  const _DriverContactView({required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    return BlocListener<DriverContactBloc, DriverContactState>(
      listenWhen: (previous, current) =>
          current.error != null && previous.error != current.error,
      listener: (context, state) =>
          showAppSnackBar(context, state.error!, type: SnackBarType.error),
      child: Scaffold(
        appBar: AppBar(title: const Text('Your driver')),
        body: SafeArea(
          child: BlocBuilder<DriverContactBloc, DriverContactState>(
            builder: (context, state) {
              final request = state.request;
              if (request == null) {
                return state.status == DriverContactStatus.failure
                    ? EmptyState.error(
                        message: state.error,
                        onRetry: () => context.read<DriverContactBloc>().add(
                          const DriverContactStarted(),
                        ),
                      )
                    : const LoadingView(message: 'Loading your driver');
              }
              if (!state.hasDriver) return _noDriver(context, request.status);
              return _Details(state: state, requestId: requestId);
            },
          ),
        ),
      ),
    );
  }

  Widget _noDriver(BuildContext context, String status) {
    final cancelled = status == RequestStatus.cancelled;
    return EmptyState(
      icon: cancelled ? Icons.close : Icons.hourglass_empty,
      title: cancelled ? 'This request was cancelled' : 'No driver yet',
      message: cancelled
          ? null
          : 'We are still finding you a driver. You will see them here.',
      actionLabel: cancelled ? 'New request' : 'Back to search',
      onAction: () => context.go(
        cancelled
            ? AppRoutes.whereFromTo
            : AppRoutes.findingDriverPath(requestId),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.state, required this.requestId});

  final DriverContactState state;
  final String requestId;

  @override
  Widget build(BuildContext context) {
    final request = state.request!;
    final driver = state.driver;

    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        Row(
          children: [
            StatusChip.request(request.status),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'A driver accepted your request',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (driver != null)
          DriverCard(driver: driver)
        else
          DriverDetailsNotice(
            loading: state.detailsStatus == DriverDetailsStatus.loading,
            message: state.error,
            onRetry: () => context.read<DriverContactBloc>().add(
              DriverDetailsRequested(request.driverId),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        if (state.detailsStatus != DriverDetailsStatus.loading)
          VehicleCard(
            vehicle: state.vehicle,
            requestedType: request.vehicleType,
          ),
        if (state.detailsStatus != DriverDetailsStatus.loading)
          const SizedBox(height: AppSpacing.md),
        PriceCard(request: request),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Continue to delivery',
          trailingIcon: Icons.arrow_forward,
          onPressed: () => context.go(AppRoutes.deliveryPath(requestId)),
        ),
      ],
    );
  }
}
