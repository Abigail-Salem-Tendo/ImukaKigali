part of 'driver_registration_bloc.dart';

/// The text fields on the two registration steps.
enum RegistrationField {
  fullName,
  phone,
  email,
  password,
  confirmPassword,
  plateNumber,
}

/// The parent of every event the registration screens can send.
sealed class DriverRegistrationEvent extends Equatable {
  /// Lets every event be created as a constant.
  const DriverRegistrationEvent();

  /// The values Equatable compares. Events with no data have none.
  @override
  List<Object?> get props => [];
}

/// Sent each time the driver types in a text field.
/// [field] says which field changed and [value] is its new text.
class RegistrationFieldChanged extends DriverRegistrationEvent {
  /// Creates the event for one field and its new text.
  const RegistrationFieldChanged(this.field, this.value);

  final RegistrationField field;
  final String value;

  /// Two of these events are equal when the field and the text match.
  @override
  List<Object?> get props => [field, value];
}

/// Sent when the driver taps a hub chip. Tapping a chosen hub removes it.
class RegistrationHubToggled extends DriverRegistrationEvent {
  /// Creates the event for the hub that was tapped.
  const RegistrationHubToggled(this.hub);

  final String hub;

  /// Two of these events are equal when the hub matches.
  @override
  List<Object?> get props => [hub];
}

/// Sent when the driver taps the eye icon on a password field.
class RegistrationPasswordVisibilityToggled extends DriverRegistrationEvent {
  /// Creates the event. It carries no data.
  const RegistrationPasswordVisibilityToggled();
}

/// Sent when the driver taps "Continue" on step 1.
class RegistrationStep1Continued extends DriverRegistrationEvent {
  /// Creates the event. It carries no data.
  const RegistrationStep1Continued();
}

/// Sent when the driver taps one of the vehicle cards on step 2.
class RegistrationVehicleTypeSelected extends DriverRegistrationEvent {
  /// Creates the event for the chosen type, one of VehicleTypes.all.
  const RegistrationVehicleTypeSelected(this.vehicleType);

  final String vehicleType;

  /// Two of these events are equal when the vehicle type matches.
  @override
  List<Object?> get props => [vehicleType];
}

/// Sent when the driver taps "Complete Registration" on step 2.
class RegistrationSubmitted extends DriverRegistrationEvent {
  /// Creates the event. It carries no data.
  const RegistrationSubmitted();
}
