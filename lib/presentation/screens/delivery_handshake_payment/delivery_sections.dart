// Owner: Member 5
// The cards of the delivery screen. Each one only draws what the DeliveryState
// says and sends events to the DeliveryBloc.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/core/theme/app_colors.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/core/widgets/widgets.dart';
import 'package:imuka_kigali/domain/entities/move_request.dart';
import 'package:imuka_kigali/domain/entities/payment.dart';
import 'package:imuka_kigali/presentation/screens/delivery_handshake_payment/delivery_bloc.dart';
import 'package:imuka_kigali/presentation/screens/job_logs/job_log_format.dart';

/// The trip and the fixed price, at the top of the screen.
class TripSummaryCard extends StatelessWidget {
  const TripSummaryCard({super.key, required this.request});

  final MoveRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dispatchNumber(request.id),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              StatusChip.request(request.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${request.pickupLocation} → ${request.dropoffLocation}',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            request.itemDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Divider(height: AppSpacing.lg),
          Row(
            children: [
              Text('Fixed price', style: theme.textTheme.bodyMedium),
              const SizedBox(width: AppSpacing.md),
              // Shrinks a long price instead of overflowing a small screen.
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    formatRwf(request.proposedAmount),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Who has confirmed the handover, and the button to confirm.
class HandshakeCard extends StatelessWidget {
  const HandshakeCard({super.key, required this.state});

  final DeliveryState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final request = state.request!;
    final canConfirm =
        !state.myConfirmed &&
        !state.confirming &&
        request.status == RequestStatus.accepted;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Handshake',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Both of you confirm when the items are handed over. '
            'Payment opens once you have both confirmed.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ConfirmRow(
            label: state.isClient ? 'You (client)' : 'Client',
            confirmed: request.clientConfirmed,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ConfirmRow(
            label: state.isClient ? 'Driver' : 'You (driver)',
            confirmed: request.driverConfirmed,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton.tonal(
            label: state.myConfirmed ? 'You confirmed' : 'Confirm handover',
            icon: state.myConfirmed ? Icons.check : Icons.handshake_outlined,
            isLoading: state.confirming,
            onPressed: canConfirm
                ? () => context.read<DeliveryBloc>().add(
                    const DeliveryConfirmed(),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({required this.label, required this.confirmed});

  final String label;
  final bool confirmed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          confirmed ? Icons.check_circle : Icons.radio_button_unchecked,
          size: AppSpacing.iconMd,
          color: confirmed
              ? AppColors.success
              : theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
        Text(
          confirmed ? 'Confirmed' : 'Waiting',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: confirmed
                ? AppColors.success
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// The client chooses how to pay and pays. The payment is simulated.
class PaymentCard extends StatelessWidget {
  const PaymentCard({super.key, required this.state});

  final DeliveryState state;

  /// Why the pay button is still off, or null when the client can pay.
  String? get _hint {
    if (!state.bothConfirmed) {
      return 'Pay opens once you and the driver have both confirmed.';
    }
    if (state.selectedMethod == null) return 'Choose a payment method.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = _hint;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'This is a simulated payment, so no real money moves.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final method in PaymentMethods.all) ...[
            _MethodTile(
              method: method,
              selected: state.selectedMethod == method,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (hint != null) ...[
            Text(
              hint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          AppButton(
            label: 'Pay ${formatRwf(state.request!.proposedAmount)}',
            icon: Icons.lock_outline,
            isLoading: state.paying,
            onPressed: state.canPay
                ? () =>
                      context.read<DeliveryBloc>().add(const PaymentSubmitted())
                : null,
          ),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({required this.method, required this.selected});

  final String method;
  final bool selected;

  IconData get _icon => method == PaymentMethods.cash
      ? Icons.payments_outlined
      : Icons.phone_android;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      highlighted: selected,
      onTap: () =>
          context.read<DeliveryBloc>().add(PaymentMethodSelected(method)),
      child: Row(
        children: [
          Icon(_icon, size: AppSpacing.iconMd),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              PaymentMethods.label(method),
              style: theme.textTheme.bodyLarge,
            ),
          ),
          if (selected)
            Icon(
              Icons.check_circle,
              size: AppSpacing.iconMd,
              color: theme.colorScheme.primary,
            ),
        ],
      ),
    );
  }
}

/// What the driver sees while the client has not paid yet.
class WaitingForPaymentCard extends StatelessWidget {
  const WaitingForPaymentCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          Icon(
            Icons.hourglass_empty,
            size: AppSpacing.iconMd,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Waiting for the client to pay. This screen updates by itself.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown to both sides once the request is completed.
class DealDoneCard extends StatelessWidget {
  const DealDoneCard({super.key, required this.state});

  final DeliveryState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final request = state.request!;
    final payment = state.payment;

    return AppCard(
      highlighted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                size: AppSpacing.iconLg,
                color: AppColors.success,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Payment complete',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            payment == null
                ? formatRwf(request.proposedAmount)
                : '${formatRwf(payment.amount)} by '
                      '${PaymentMethods.label(payment.method)}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          if (state.isClient)
            AppButton(
              label: 'Rate your driver',
              icon: Icons.star_outline,
              onPressed: () => context.go(AppRoutes.ratePath(request.id)),
            )
          else
            AppButton(
              label: 'Back to my jobs',
              icon: Icons.arrow_back,
              onPressed: () => context.go(AppRoutes.driverJobs),
            ),
        ],
      ),
    );
  }
}
