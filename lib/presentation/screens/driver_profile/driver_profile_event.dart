part of 'driver_profile_bloc.dart';

/// The parent of every event the driver profile screen can send.
sealed class DriverProfileEvent extends Equatable {
  /// Lets every event be created as a constant.
  const DriverProfileEvent();

  /// The values Equatable compares. Events with no data have none.
  @override
  List<Object?> get props => [];
}

/// Sent when the profile opens, or when "Try again" is tapped, to load
/// the vehicle of the driver with the id [driverId].
class DriverProfileRequested extends DriverProfileEvent {
  /// Creates the event for one driver.
  const DriverProfileRequested(this.driverId);

  final String driverId;

  /// Two of these events are equal when the driver id matches.
  @override
  List<Object?> get props => [driverId];
}

/// Sent when the driver picks a different vehicle type.
class DriverVehicleTypeChanged extends DriverProfileEvent {
  /// Creates the event for the new type, one of VehicleTypes.all.
  const DriverVehicleTypeChanged(this.vehicleType);

  final String vehicleType;

  /// Two of these events are equal when the vehicle type matches.
  @override
  List<Object?> get props => [vehicleType];
}

/// Sent when the driver saves a new plate number in the plate dialog.
class DriverPlateNumberChanged extends DriverProfileEvent {
  /// Creates the event for the new plate number.
  const DriverPlateNumberChanged(this.plateNumber);

  final String plateNumber;

  /// Two of these events are equal when the plate number matches.
  @override
  List<Object?> get props => [plateNumber];
}

/// Sent when a driver without a vehicle adds one.
class DriverVehicleAdded extends DriverProfileEvent {
  /// Creates the event with the type and plate of the new vehicle.
  const DriverVehicleAdded({
    required this.vehicleType,
    required this.plateNumber,
  });

  final String vehicleType;
  final String plateNumber;

  /// Two of these events are equal when the type and the plate match.
  @override
  List<Object?> get props => [vehicleType, plateNumber];
}

/// Sent when the driver confirms "Remove this vehicle?".
class DriverVehicleDeleted extends DriverProfileEvent {
  /// Creates the event. It carries no data.
  const DriverVehicleDeleted();
}
