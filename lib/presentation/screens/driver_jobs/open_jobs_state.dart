// Owner: Member 4
part of 'open_jobs_bloc.dart';

enum OpenJobsStatus { initial, loading, noVehicle, success, failure }

class OpenJobsState extends Equatable {
  const OpenJobsState({
    this.status = OpenJobsStatus.initial,
    this.vehicle,
    this.jobs = const [],
    this.error,
  });

  final OpenJobsStatus status;
  final Vehicle? vehicle;
  final List<MoveRequest> jobs;
  final String? error;

  OpenJobsState copyWith({
    OpenJobsStatus? status,
    Vehicle? vehicle,
    List<MoveRequest>? jobs,
    String? error,
  }) => OpenJobsState(
    status: status ?? this.status,
    vehicle: vehicle ?? this.vehicle,
    jobs: jobs ?? this.jobs,
    error: error,
  );

  @override
  List<Object?> get props => [status, vehicle, jobs, error];
}
