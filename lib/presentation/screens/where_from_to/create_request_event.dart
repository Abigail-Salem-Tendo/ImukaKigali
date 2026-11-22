// Owner: Member 3
// Events for create_request_bloc.dart. First line will be: part of 'create_request_bloc.dart';
part of 'create_request_bloc.dart';

sealed class CreateRequestEvent extends Equatable {
  const CreateRequestEvent();

  @override
  List<Object?> get props => [];
}

class PickupSelected extends CreateRequestEvent {
  const PickupSelected(this.area);
  final KigaliArea area;

  @override
  List<Object?> get props => [area.name];
}

class DropoffSelected extends CreateRequestEvent {
  const DropoffSelected(this.area);
  final KigaliArea area;

  @override
  List<Object?> get props => [area.name];
}

class VehicleTypeSelected extends CreateRequestEvent {
  const VehicleTypeSelected(this.vehicleType);
  final String vehicleType;

  @override
  List<Object?> get props => [vehicleType];
}

class ItemDescriptionChanged extends CreateRequestEvent {
  const ItemDescriptionChanged(this.description);
  final String description;

  @override
  List<Object?> get props => [description];
}

class RequestSubmitted extends CreateRequestEvent {
  const RequestSubmitted(this.clientId);
  final String clientId;

  @override
  List<Object?> get props => [clientId];
}
