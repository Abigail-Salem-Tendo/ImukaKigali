// Owner: Member 4
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imuka_kigali/domain/entities/move_request.dart';
import 'package:imuka_kigali/domain/repositories/driver_job_repository.dart';

part 'open_jobs_event.dart';
part 'open_jobs_state.dart';

class OpenJobsBloc extends Bloc<OpenJobsEvent, OpenJobsState> {
  OpenJobsBloc(this._jobRepo) : super(const OpenJobsState()) {
    on<OpenJobsStarted>(_onStarted);
  }

  final DriverJobRepository _jobRepo;

  Future<void> _onStarted(
    OpenJobsStarted event,
    Emitter<OpenJobsState> emit,
  ) async {
    emit(state.copyWith(status: OpenJobsStatus.loading));
    await emit.forEach<List<MoveRequest>>(
      _jobRepo.watchOpenJobs(event.vehicleType),
      onData: (jobs) =>
          state.copyWith(status: OpenJobsStatus.success, jobs: jobs),
      onError: (error, _) => state.copyWith(
        status: OpenJobsStatus.failure,
        error: error.toString().replaceFirst('Exception: ', ''),
      ),
    );
  }
}
