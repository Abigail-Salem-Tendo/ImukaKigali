part of 'driver_profile_bloc.dart';

/// Where the profile is: not loaded yet, loading, ready, or failed.
enum DriverProfileStatus { initial, loading, success, failure }

/// Everything the driver profile screen needs to draw the vehicle part.
/// The driver's name, phone and email come from the global AuthBloc.
class DriverProfileState extends Equatable {
  /// Creates a state. With no arguments nothing has been loaded yet.
  const DriverProfileState({
    this.status = DriverProfileStatus.initial,
    this.hasLoaded = false,
    this.vehicle,
    this.isSaving = false,
    this.message,
    this.error,
  });

  final DriverProfileStatus status;

  /// True once the first load has finished, with or without a vehicle.
  final bool hasLoaded;

  /// The driver's vehicle, or null if they have none.
  final Vehicle? vehicle;

  /// True while a new vehicle is being added.
  final bool isSaving;

  /// A short success message for a snackbar, for example "Vehicle removed."
  final String? message;

  /// A readable error message for a snackbar.
  final String? error;

  /// Returns a copy of this state with only the given values replaced.
  /// Pass [clearVehicle] as true to set the vehicle back to null, because
  /// passing null for [vehicle] means "keep the current one".
  /// [message] and [error] are cleared unless new ones are passed.
  DriverProfileState copyWith({
    DriverProfileStatus? status,
    bool? hasLoaded,
    Vehicle? vehicle,
    bool clearVehicle = false,
    bool? isSaving,
    String? message,
    String? error,
  }) {
    return DriverProfileState(
      status: status ?? this.status,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      vehicle: clearVehicle ? null : vehicle ?? this.vehicle,
      isSaving: isSaving ?? this.isSaving,
      message: message,
      error: error,
    );
  }

  /// The values Equatable compares to decide if the screen must redraw.
  @override
  List<Object?> get props => [
    status,
    hasLoaded,
    vehicle,
    isSaving,
    message,
    error,
  ];
}
