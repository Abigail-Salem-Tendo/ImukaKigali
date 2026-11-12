
part of 'driver_profile_bloc.dart';

sealed class DriverProfileEvent extends Equatable {
  const DriverProfileEvent();

  @override
  List<Object?> get props => [];
}

/// The profile screen opened (or "Try again" was tapped): load the vehicle.
class DriverProfileRequested extends DriverProfileEvent {
  const DriverProfileRequested(this.driverId);

  final String driverId;

  @override
  List<Object?> get props => [driverId];
}

/// The driver picked a different vehicle class.
class DriverVehicleTypeChanged extends DriverProfileEvent {
  const DriverVehicleTypeChanged(this.vehicleType);

  final VehicleType vehicleType;

  @override
  List<Object?> get props => [vehicleType];
}

/// The driver saved a new plate number in the plate dialog.
class DriverPlateNumberChanged extends DriverProfileEvent {
  const DriverPlateNumberChanged(this.plateNumber);

  final String plateNumber;

  @override
  List<Object?> get props => [plateNumber];
}

/// The driver tapped a hub chip under "Operational Zones".
class DriverHubToggled extends DriverProfileEvent {
  const DriverHubToggled(this.hub);

  final String hub;

  @override
  List<Object?> get props => [hub];
}

/// The driver had no vehicle and added one.
class DriverVehicleAdded extends DriverProfileEvent {
  const DriverVehicleAdded({
    required this.vehicleType,
    required this.plateNumber,
  });

  final VehicleType vehicleType;
  final String plateNumber;

  @override
  List<Object?> get props => [vehicleType, plateNumber];
}

/// The driver confirmed "Remove this vehicle?".
class DriverVehicleDeleted extends DriverProfileEvent {
  const DriverVehicleDeleted();
}
