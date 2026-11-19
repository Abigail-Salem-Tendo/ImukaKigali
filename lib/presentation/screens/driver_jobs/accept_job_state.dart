// Owner: Member 4
part of 'accept_job_bloc.dart';

enum AcceptJobStatus { initial, loading, success, failure }

class AcceptJobState extends Equatable {
  const AcceptJobState({
    this.status = AcceptJobStatus.initial,
    this.acceptingJobId,
    this.acceptedJob,
    this.client,
    this.error,
  });

  final AcceptJobStatus status;

  /// The job whose Accept button shows a spinner.
  final String? acceptingJobId;
  final MoveRequest? acceptedJob;

  /// Null when the client's profile could not be read.
  final AppUser? client;
  final String? error;

  bool get isAccepting => status == AcceptJobStatus.loading;

  @override
  List<Object?> get props => [
    status,
    acceptingJobId,
    acceptedJob,
    client,
    error,
  ];
}
