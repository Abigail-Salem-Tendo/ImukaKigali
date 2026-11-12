

part of 'driver_profile_bloc.dart';

enum DriverProfileStatus { initial, loading, success, failure }

class DriverProfileState extends Equatable {
  const DriverProfileState({
    this.status = DriverProfileStatus.initial,
    this.hasLoaded = false,
    this.vehicle,
    this.isSaving = false,
    this.message,
    this.error,
  });

  final DriverProfileStatus status;

  /// True once the first load has finished (with or without a vehicle).
  final bool hasLoaded;

  /// The driver's vehicle, or null if they have none (or just deleted it).
  final Vehicle? vehicle;

  /// True while a new vehicle is being added (shows a spinner on the button).
  final bool isSaving;

  /// A short success message for a snackbar, e.g. "Vehicle removed."
  final String? message;

  /// A friendly error message for a snackbar.
  final String? error;

  /// Makes a copy with only some values changed.
  ///
  /// [clearVehicle] exists because "vehicle ?? this.vehicle" can never set
  /// the vehicle back to null. After a delete we pass clearVehicle: true.
  /// Like the team template, [message] and [error] are cleared unless passed.
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
