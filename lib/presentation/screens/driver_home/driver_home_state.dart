// Owner: Member 4
part of 'driver_home_bloc.dart';

enum DriverHomeStatus { initial, loading, noVehicle, success, failure }

class DriverHomeState extends Equatable {
  const DriverHomeState({
    this.status = DriverHomeStatus.initial,
    this.vehicle,
    this.openJobCount = 0,
    this.myJobs = const [],
    this.error,
  });

  final DriverHomeStatus status;
  final Vehicle? vehicle;
  final int openJobCount;
  final List<MoveRequest> myJobs;
  final String? error;

  List<MoveRequest> get acceptedJobs =>
      myJobs.where((job) => job.status == RequestStatus.accepted).toList();

  List<MoveRequest> get _completedJobs =>
      myJobs.where((job) => job.status == RequestStatus.completed).toList();

  double get totalEarnings =>
      _completedJobs.fold(0, (sum, job) => sum + job.proposedAmount);

  int get completedCount => _completedJobs.length;

  // The error is kept, so an update from one live list does not hide the
  // error of the other. A new start begins from a fresh state instead.
  DriverHomeState copyWith({
    DriverHomeStatus? status,
    Vehicle? vehicle,
    int? openJobCount,
    List<MoveRequest>? myJobs,
    String? error,
  }) => DriverHomeState(
    status: status ?? this.status,
    vehicle: vehicle ?? this.vehicle,
    openJobCount: openJobCount ?? this.openJobCount,
    myJobs: myJobs ?? this.myJobs,
    error: error ?? this.error,
  );

  @override
  List<Object?> get props => [status, vehicle, openJobCount, myJobs, error];
}
