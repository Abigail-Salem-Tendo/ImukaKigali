// Owner: Member 4
part of 'open_jobs_bloc.dart';

sealed class OpenJobsEvent extends Equatable {
  const OpenJobsEvent();

  @override
  List<Object?> get props => [];
}

class OpenJobsStarted extends OpenJobsEvent {
  const OpenJobsStarted(this.driverId);

  final String driverId;

  @override
  List<Object?> get props => [driverId];
}
