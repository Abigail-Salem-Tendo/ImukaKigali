// Owner: Member 5
part of 'delivery_bloc.dart';

enum DeliveryStatus { loading, ready, failure }

class DeliveryState extends Equatable {
  const DeliveryState({
    this.status = DeliveryStatus.loading,
    this.request,
    this.payment,
    this.isClient = false,
    this.selectedMethod,
    this.confirming = false,
    this.paying = false,
    this.error,
  });

  final DeliveryStatus status;
  final MoveRequest? request;

  /// The saved payment, once the client has paid.
  final Payment? payment;

  /// true when the person using the app is the client of this request,
  /// false when they are the driver.
  final bool isClient;

  /// The payment method the client picked (PaymentMethods.x), or null.
  final String? selectedMethod;
  final bool confirming;
  final bool paying;
  final String? error;

  /// Has the person using the app already confirmed their side?
  bool get myConfirmed => isClient
      ? request?.clientConfirmed ?? false
      : request?.driverConfirmed ?? false;

  /// Has the other person confirmed their side?
  bool get otherConfirmed => isClient
      ? request?.driverConfirmed ?? false
      : request?.clientConfirmed ?? false;

  bool get bothConfirmed => myConfirmed && otherConfirmed;

  /// The deal is finished: paid and the request is `completed`.
  bool get isCompleted => request?.status == RequestStatus.completed;

  /// Only the client pays, and only after both sides confirmed and a method
  /// is picked. Never twice.
  bool get canPay =>
      isClient &&
      bothConfirmed &&
      !isCompleted &&
      !paying &&
      request?.status == RequestStatus.accepted &&
      selectedMethod != null;

  /// [error] is not carried over, so each error is shown once.
  DeliveryState copyWith({
    DeliveryStatus? status,
    MoveRequest? request,
    Payment? payment,
    bool? isClient,
    String? selectedMethod,
    bool? confirming,
    bool? paying,
    String? error,
  }) => DeliveryState(
    status: status ?? this.status,
    request: request ?? this.request,
    payment: payment ?? this.payment,
    isClient: isClient ?? this.isClient,
    selectedMethod: selectedMethod ?? this.selectedMethod,
    confirming: confirming ?? this.confirming,
    paying: paying ?? this.paying,
    error: error,
  );

  @override
  List<Object?> get props => [
    status,
    request,
    payment,
    isClient,
    selectedMethod,
    confirming,
    paying,
    error,
  ];
}
