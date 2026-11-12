
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

sealed class DriverRegistrationEvent extends Equatable {
  const DriverRegistrationEvent();

  @override
  List<Object?> get props => [];
}

/// The driver typed in one of the text fields.
/// One event for all fields keeps the bloc short: [field] says which one.
class RegistrationFieldChanged extends DriverRegistrationEvent {
  const RegistrationFieldChanged(this.field, this.value);

  final RegistrationField field;
  final String value;

  @override
  List<Object?> get props => [field, value];
}

/// The driver tapped a hub chip (tap once to pick, tap again to unpick).
class RegistrationHubToggled extends DriverRegistrationEvent {
  const RegistrationHubToggled(this.hub);

  final String hub;

  @override
  List<Object?> get props => [hub];
}

/// The driver tapped the eye icon on a password field.
class RegistrationPasswordVisibilityToggled extends DriverRegistrationEvent {
  const RegistrationPasswordVisibilityToggled();
}

/// The driver tapped "Continue" on step 1, so start showing step 1's errors.
class RegistrationStep1Continued extends DriverRegistrationEvent {
  const RegistrationStep1Continued();
}

/// The driver tapped one of the three vehicle class cards on step 2.
class RegistrationVehicleTypeSelected extends DriverRegistrationEvent {
  const RegistrationVehicleTypeSelected(this.vehicleType);

  final VehicleType vehicleType;

  @override
  List<Object?> get props => [vehicleType];
}

/// The driver tapped "Complete Registration" on step 2.
class RegistrationSubmitted extends DriverRegistrationEvent {
  const RegistrationSubmitted();
}
0