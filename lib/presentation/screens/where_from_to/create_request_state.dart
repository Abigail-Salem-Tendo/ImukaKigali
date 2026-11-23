// Owner: Member 3
// State for create_request_bloc.dart. First line will be: part of 'create_request_bloc.dart';
part of 'create_request_bloc.dart';

enum CreateRequestStatus { initial, submitting, success, failure }

class CreateRequestState extends Equatable {
  const CreateRequestState({
    this.pickup,
    this.dropoff,
    this.vehicleType,
    this.itemDescription = '',
    this.status = CreateRequestStatus.initial,
    this.requestId,
    this.error,
  });

  final KigaliArea? pickup;
  final KigaliArea? dropoff;
  final String? vehicleType;
  final String itemDescription;
  final CreateRequestStatus status;
  final String? requestId;
  final String? error;

  CreateRequestState copyWith({
    KigaliArea? pickup,
    KigaliArea? dropoff,
    String? vehicleType,
    String? itemDescription,
    CreateRequestStatus? status,
    String? requestId,
    String? error,
  }) => CreateRequestState(
    pickup: pickup ?? this.pickup,
    dropoff: dropoff ?? this.dropoff,
    vehicleType: vehicleType ?? this.vehicleType,
    itemDescription: itemDescription ?? this.itemDescription,
    status: status ?? this.status,
    requestId: requestId ?? this.requestId,
    error: error,
  );

  /// Both areas chosen and they are different.
  bool get hasRoute =>
      pickup != null && dropoff != null && pickup!.name != dropoff!.name;

  /// The price shown to the client. Null until route and vehicle are chosen.
  double? get proposedAmount {
    if (!hasRoute || vehicleType == null) return null;
    return FareCalculator.calculate(
      pickup: pickup!,
      dropoff: dropoff!,
      vehicleType: vehicleType!,
    ).proposedAmount;
  }

  bool get canSubmit =>
      proposedAmount != null &&
      itemDescription.trim().isNotEmpty &&
      status != CreateRequestStatus.submitting;

  @override
  List<Object?> get props => [
    pickup?.name,
    dropoff?.name,
    vehicleType,
    itemDescription,
    status,
    requestId,
    error,
  ];
}
