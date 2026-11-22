// Owner: Member 5
part of 'driver_contact_bloc.dart';

sealed class DriverContactEvent extends Equatable {
  const DriverContactEvent();

  @override
  List<Object?> get props => [];
}

/// Starts listening to the request, and loads the driver once there is one.
class DriverContactStarted extends DriverContactEvent {
  const DriverContactStarted();
}

/// Loads the driver's profile and vehicle. Sent by the bloc itself when the
/// request gets a driver, and by the screen's "Try again" button.
class DriverDetailsRequested extends DriverContactEvent {
  const DriverDetailsRequested(this.driverId);

  final String driverId;

  @override
  List<Object?> get props => [driverId];
}
