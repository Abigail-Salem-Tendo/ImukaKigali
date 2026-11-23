// Owner: Member 5
part of 'driver_contact_bloc.dart';

enum DriverContactStatus { loading, ready, failure }

/// Loading the driver's profile and vehicle is separate from the request, so
/// the price and trip show even if the driver's details fail to load.
enum DriverDetailsStatus { loading, loaded, failure }

class DriverContactState extends Equatable {
  const DriverContactState({
    this.status = DriverContactStatus.loading,
    this.request,
    this.detailsStatus = DriverDetailsStatus.loading,
    this.driver,
    this.vehicle,
    this.error,
  });

  final DriverContactStatus status;
  final MoveRequest? request;
  final DriverDetailsStatus detailsStatus;

  /// The driver's profile (name and phone). Null if it could not be loaded.
  final AppUser? driver;

  /// The driver's vehicle. Null if they have none or it could not be loaded.
  final Vehicle? vehicle;
  final String? error;

  /// A driver has accepted: the request has a driver and is not cancelled.
  bool get hasDriver =>
      request != null &&
      request!.driverId.isNotEmpty &&
      request!.status != RequestStatus.cancelled;

  /// [error] is not carried over, so each error is shown once.
  DriverContactState copyWith({
    DriverContactStatus? status,
    MoveRequest? request,
    DriverDetailsStatus? detailsStatus,
    AppUser? driver,
    Vehicle? vehicle,
    String? error,
  }) => DriverContactState(
    status: status ?? this.status,
    request: request ?? this.request,
    detailsStatus: detailsStatus ?? this.detailsStatus,
    driver: driver ?? this.driver,
    vehicle: vehicle ?? this.vehicle,
    error: error,
  );

  @override
  List<Object?> get props => [
    status,
    request,
    detailsStatus,
    driver,
    vehicle,
    error,
  ];
}
