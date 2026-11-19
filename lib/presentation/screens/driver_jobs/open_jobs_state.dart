// Owner: Member 4
part of 'open_jobs_bloc.dart';

enum OpenJobsStatus { initial, loading, success, failure }

class OpenJobsState extends Equatable {
  const OpenJobsState({
    this.status = OpenJobsStatus.initial,
    this.jobs = const [],
    this.error,
  });

  final OpenJobsStatus status;
  final List<MoveRequest> jobs;
  final String? error;

  OpenJobsState copyWith({
    OpenJobsStatus? status,
    List<MoveRequest>? jobs,
    String? error,
  }) => OpenJobsState(
    status: status ?? this.status,
    jobs: jobs ?? this.jobs,
    error: error,
  );

  @override
  List<Object?> get props => [status, jobs, error];
}
