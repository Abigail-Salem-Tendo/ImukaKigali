// Owner: Member 4
part of 'job_logs_bloc.dart';

sealed class JobLogsEvent extends Equatable {
  const JobLogsEvent();

  @override
  List<Object?> get props => [];
}

class JobLogsRequested extends JobLogsEvent {
  const JobLogsRequested(this.driverId);

  final String driverId;

  @override
  List<Object?> get props => [driverId];
}

class JobLogsPeriodChanged extends JobLogsEvent {
  const JobLogsPeriodChanged(this.period);

  final JobLogsPeriod period;

  @override
  List<Object?> get props => [period];
}
