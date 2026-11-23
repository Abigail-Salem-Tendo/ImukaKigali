// Owner: Member 5
// Screen: delivery handshake + simulated payment. Used by the client and the
// driver. Route: AppRoutes.delivery.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/core/widgets/widgets.dart';
import 'package:imuka_kigali/domain/repositories/payment_repository.dart';
import 'package:imuka_kigali/domain/repositories/request_repository.dart';
import 'package:imuka_kigali/presentation/screens/delivery_handshake_payment/delivery_bloc.dart';
import 'package:imuka_kigali/presentation/screens/delivery_handshake_payment/delivery_sections.dart';
import 'package:imuka_kigali/presentation/screens/login/auth_bloc.dart';

/// Creates its own bloc. The viewer is the signed-in user, which is how the
/// bloc knows if this is the client or the driver.
class DeliveryHandshakePaymentScreen extends StatelessWidget {
  const DeliveryHandshakePaymentScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    final viewerId = context.read<AuthBloc>().state.user?.uid ?? '';
    return BlocProvider(
      create: (context) => DeliveryBloc(
        context.read<RequestRepository>(),
        context.read<PaymentRepository>(),
        requestId,
        viewerId,
      )..add(const DeliveryStarted()),
      child: const _DeliveryView(),
    );
  }
}

class _DeliveryView extends StatelessWidget {
  const _DeliveryView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeliveryBloc, DeliveryState>(
      listenWhen: (previous, current) =>
          current.error != null && previous.error != current.error,
      listener: (context, state) =>
          showAppSnackBar(context, state.error!, type: SnackBarType.error),
      child: Scaffold(
        appBar: AppBar(title: const Text('Delivery')),
        body: SafeArea(
          child: BlocBuilder<DeliveryBloc, DeliveryState>(
            builder: (context, state) {
              final request = state.request;
              if (request == null) {
                return state.status == DeliveryStatus.failure
                    ? EmptyState.error(
                        message: state.error,
                        onRetry: () => context.read<DeliveryBloc>().add(
                          const DeliveryStarted(),
                        ),
                      )
                    : const LoadingView(message: 'Loading your delivery');
              }
              return ListView(
                padding: AppSpacing.screenPadding,
                children: [
                  TripSummaryCard(request: request),
                  const SizedBox(height: AppSpacing.md),
                  ..._body(state),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// The cards under the trip, for what the request is doing right now.
  List<Widget> _body(DeliveryState state) {
    if (state.isCompleted) return [DealDoneCard(state: state)];

    final status = state.request!.status;
    if (status != RequestStatus.accepted) {
      return [
        EmptyState(
          icon: Icons.info_outline,
          title: status == RequestStatus.cancelled
              ? 'This request was cancelled'
              : 'No driver has accepted yet',
          message: 'There is nothing to hand over or pay for.',
        ),
      ];
    }

    return [
      HandshakeCard(state: state),
      const SizedBox(height: AppSpacing.md),
      if (state.isClient)
        PaymentCard(state: state)
      else
        const WaitingForPaymentCard(),
    ];
  }
}
