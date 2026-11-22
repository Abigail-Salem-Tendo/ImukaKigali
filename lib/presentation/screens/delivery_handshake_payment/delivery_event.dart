// Owner: Member 5
part of 'delivery_bloc.dart';

sealed class DeliveryEvent extends Equatable {
  const DeliveryEvent();

  @override
  List<Object?> get props => [];
}

/// Starts listening to the request and loads its payment, if there is one.
class DeliveryStarted extends DeliveryEvent {
  const DeliveryStarted();
}

/// The person using the app confirms the handshake (their own flag only).
class DeliveryConfirmed extends DeliveryEvent {
  const DeliveryConfirmed();
}

/// The client picks how to pay (one of PaymentMethods.all).
class PaymentMethodSelected extends DeliveryEvent {
  const PaymentMethodSelected(this.method);

  final String method;

  @override
  List<Object?> get props => [method];
}

/// The client taps pay: saves the payment, then completes the request.
class PaymentSubmitted extends DeliveryEvent {
  const PaymentSubmitted();
}
