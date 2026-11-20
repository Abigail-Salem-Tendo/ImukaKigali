// Owner: Member 4
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/domain/entities/move_request.dart';
import 'package:imuka_kigali/domain/repositories/auth_repository.dart';
import 'package:imuka_kigali/domain/repositories/driver_job_repository.dart';

part 'job_logs_event.dart';
part 'job_logs_state.dart';

class JobLogsBloc extends Bloc<JobLogsEvent, JobLogsState> {
  JobLogsBloc(this._jobRepo, this._authRepo) : super(const JobLogsState()) {
    on<JobLogsRequested>(_onRequested);
    on<JobLogsPeriodChanged>(_onPeriodChanged);
  }

  final DriverJobRepository _jobRepo;
  final AuthRepository _authRepo;

  // Kept between stream updates so a client's name is read only once,
  // not every time one of my jobs changes.
  final Map<String, String> _clientNames = {};

  Future<void> _onRequested(
    JobLogsRequested event,
    Emitter<JobLogsState> emit,
  ) async {
    if (event.driverId.isEmpty) {
      emit(
        state.copyWith(
          status: JobLogsStatus.failure,
          error: 'Please sign in again to see your jobs',
        ),
      );
      return;
    }
    emit(state.copyWith(status: JobLogsStatus.loading));
    final myJobs = _jobRepo
        .watchMyJobs(event.driverId)
        .asyncMap(_loadClientNames);
    await emit.forEach<List<MoveRequest>>(
      myJobs,
      onData: (jobs) => state.copyWith(
        status: JobLogsStatus.success,
        allJobs: jobs,
        visibleJobs: _jobsInPeriod(jobs, state.period),
        clientNames: Map.of(_clientNames),
      ),
      onError: (error, _) => state.copyWith(
        status: JobLogsStatus.failure,
        error: error.toString().replaceFirst('Exception: ', ''),
      ),
    );
  }

  void _onPeriodChanged(
    JobLogsPeriodChanged event,
    Emitter<JobLogsState> emit,
  ) {
    emit(
      state.copyWith(
        period: event.period,
        visibleJobs: _jobsInPeriod(state.allJobs, event.period),
      ),
    );
  }

  Future<List<MoveRequest>> _loadClientNames(List<MoveRequest> jobs) async {
    final clientIds = jobs.map((job) => job.clientId).toSet();
    for (final clientId in clientIds) {
      if (_clientNames.containsKey(clientId)) continue;
      try {
        final client = await _authRepo.getUser(clientId);
        _clientNames[clientId] = client?.fullName ?? '';
      } catch (_) {
        // A missing name should not hide all my jobs. The card shows "Client",
        // and nothing is cached, so the name is tried again on the next update.
      }
    }
    return jobs;
  }

  List<MoveRequest> _jobsInPeriod(
    List<MoveRequest> jobs,
    JobLogsPeriod period,
  ) {
    final now = DateTime.now();
    final start = switch (period) {
      JobLogsPeriod.allTrips => null,
      JobLogsPeriod.thisWeek => DateTime(
        now.year,
        now.month,
        now.day - (now.weekday - DateTime.monday),
      ),
      JobLogsPeriod.thisMonth => DateTime(now.year, now.month),
    };
    if (start == null) return jobs;
    return jobs.where((job) => !job.createdAt.isBefore(start)).toList();
  }
}
