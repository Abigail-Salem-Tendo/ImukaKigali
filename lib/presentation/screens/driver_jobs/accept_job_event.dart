// Owner: Member 4
part of 'accept_job_bloc.dart';

sealed class AcceptJobEvent extends Equatable {
  const AcceptJobEvent();

  @override
  List<Object?> get props => [];
}

class JobAccepted extends AcceptJobEvent {
  const JobAccepted(this.job);

  // The whole job, not only its id, because it leaves the open list as soon
  // as it is accepted and the screen still needs its details.
  final MoveRequest job;

  @override
  List<Object?> get props => [job];
}
