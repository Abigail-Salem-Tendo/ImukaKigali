// Owner: Member 4
part of 'driver_home_bloc.dart';

sealed class DriverHomeEvent extends Equatable {
  const DriverHomeEvent();

  @override
  List<Object?> get props => [];
}

class DriverHomeStarted extends DriverHomeEvent {
  const DriverHomeStarted(this.driverId);

  final String driverId;

  @override
  List<Object?> get props => [driverId];
}
