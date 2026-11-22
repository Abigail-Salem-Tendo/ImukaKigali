// Owner: Member 5
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/domain/entities/move_request.dart';
import 'package:imuka_kigali/domain/entities/payment.dart';
import 'package:imuka_kigali/domain/repositories/payment_repository.dart';
import 'package:imuka_kigali/domain/repositories/request_repository.dart';

part 'delivery_event.dart';
part 'delivery_state.dart';

/// The handshake and the simulated payment, for both the client and the
/// driver. Each one confirms their own flag on the request. When both are
/// true the client can pay, and paying completes the request.
class DeliveryBloc extends Bloc<DeliveryEvent, DeliveryState> {
  /// [viewerId] is the uid of the person using the app (from AuthBloc).
  DeliveryBloc(this._requests, this._payments, this.requestId, this.viewerId)
    : super(const DeliveryState()) {
    on<DeliveryStarted>(_onStarted);
    on<DeliveryConfirmed>(_onConfirmed);
    on<PaymentMethodSelected>(_onMethodSelected);
    on<PaymentSubmitted>(_onPaymentSubmitted);
  }

  final RequestRepository _requests;
  final PaymentRepository _payments;
  final String requestId;
  final String viewerId;

  Future<void> _onStarted(
    DeliveryStarted event,
    Emitter<DeliveryState> emit,
  ) async {
    // A payment that already exists (the screen was reopened) is shown too.
    try {
      final payment = await _payments.getPaymentForRequest(requestId);
      if (payment != null) emit(state.copyWith(payment: payment));
    } catch (e) {
      emit(state.copyWith(error: _message(e)));
    }

    await emit.forEach<MoveRequest?>(
      _requests.watchRequest(requestId),
      onData: _fromRequest,
      onError: (error, _) => state.copyWith(
        status: DeliveryStatus.failure,
        error: _message(error),
      ),
    );
  }

  DeliveryState _fromRequest(MoveRequest? request) {
    if (request == null) {
      return state.copyWith(
        status: DeliveryStatus.failure,
        error: 'Request not found',
      );
    }
    return state.copyWith(
      status: DeliveryStatus.ready,
      request: request,
      isClient: request.clientId == viewerId,
    );
  }

  // The live stream reports the new flag, so the screen updates by itself.
  Future<void> _onConfirmed(
    DeliveryConfirmed event,
    Emitter<DeliveryState> emit,
  ) async {
    final request = state.request;
    if (request == null || state.myConfirmed) return;
    if (request.status != RequestStatus.accepted) {
      emit(state.copyWith(error: 'This delivery is no longer active'));
      return;
    }

    // Each side only ever sets its own flag.
    final flag = state.isClient
        ? Fields.clientConfirmed
        : Fields.driverConfirmed;

    emit(state.copyWith(confirming: true));
    try {
      await _requests.updateRequest(requestId, {flag: true});
      emit(state.copyWith(confirming: false));
    } catch (e) {
      emit(state.copyWith(confirming: false, error: _message(e)));
    }
  }

  void _onMethodSelected(
    PaymentMethodSelected event,
    Emitter<DeliveryState> emit,
  ) {
    emit(state.copyWith(selectedMethod: event.method));
  }

  Future<void> _onPaymentSubmitted(
    PaymentSubmitted event,
    Emitter<DeliveryState> emit,
  ) async {
    final request = state.request;
    final method = state.selectedMethod;
    if (request == null || method == null || !state.canPay) return;

    emit(state.copyWith(paying: true));
    try {
      // If a first try saved the payment but failed to complete the request,
      // the retry reuses that payment instead of paying twice.
      var payment = await _payments.getPaymentForRequest(requestId);
      if (payment == null) {
        await _payments.createPayment(
          Payment(
            id: requestId,
            requestId: requestId,
            amount: request.proposedAmount,
            method: method,
            status: PaymentStatus.paid,
          ),
        );
        payment = await _payments.getPaymentForRequest(requestId);
      }
      await _requests.updateRequest(requestId, {
        Fields.status: RequestStatus.completed,
      });
      emit(state.copyWith(paying: false, payment: payment));
    } catch (e) {
      emit(state.copyWith(paying: false, error: _message(e)));
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
