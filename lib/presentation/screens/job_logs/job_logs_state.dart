// Owner: Member 4
part of 'job_logs_bloc.dart';

enum JobLogsStatus { initial, loading, success, failure }

enum JobLogsPeriod { allTrips, thisWeek, thisMonth }

class JobLogsState extends Equatable {
  const JobLogsState({
    this.status = JobLogsStatus.initial,
    this.period = JobLogsPeriod.allTrips,
    this.allJobs = const [],
    this.visibleJobs = const [],
    this.clientNames = const {},
    this.error,
  });

  final JobLogsStatus status;
  final JobLogsPeriod period;
  final List<MoveRequest> allJobs;
  final List<MoveRequest> visibleJobs;
  final Map<String, String> clientNames;
  final String? error;

  double get totalEarnings => visibleJobs
      .where((job) => job.status == RequestStatus.completed)
      .fold(0, (sum, job) => sum + job.proposedAmount);

  int get completedCount =>
      visibleJobs.where((job) => job.status == RequestStatus.completed).length;

  int get inProgressCount =>
      visibleJobs.where((job) => job.status == RequestStatus.accepted).length;

  JobLogsState copyWith({
    JobLogsStatus? status,
    JobLogsPeriod? period,
    List<MoveRequest>? allJobs,
    List<MoveRequest>? visibleJobs,
    Map<String, String>? clientNames,
    String? error,
  }) => JobLogsState(
    status: status ?? this.status,
    period: period ?? this.period,
    allJobs: allJobs ?? this.allJobs,
    visibleJobs: visibleJobs ?? this.visibleJobs,
    clientNames: clientNames ?? this.clientNames,
    error: error,
  );

  @override
  List<Object?> get props => [
    status,
    period,
    allJobs,
    visibleJobs,
    clientNames,
    error,
  ];
}
