// Owner: Member 4
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imuka_kigali/domain/entities/app_user.dart';
import 'package:imuka_kigali/domain/entities/move_request.dart';
import 'package:imuka_kigali/domain/repositories/auth_repository.dart';
import 'package:imuka_kigali/domain/repositories/driver_job_repository.dart';

part 'accept_job_event.dart';
part 'accept_job_state.dart';

class AcceptJobBloc extends Bloc<AcceptJobEvent, AcceptJobState> {
  AcceptJobBloc(this._jobRepo, this._authRepo) : super(const AcceptJobState()) {
    on<JobAccepted>(_onAccepted);
  }

  final DriverJobRepository _jobRepo;
  final AuthRepository _authRepo;

  Future<void> _onAccepted(
    JobAccepted event,
    Emitter<AcceptJobState> emit,
  ) async {
    // A driver takes one job at a time, so a second tap while one is being
    // accepted is ignored.
    if (state.isAccepting) return;
    emit(
      AcceptJobState(
        status: AcceptJobStatus.loading,
        acceptingJobId: event.job.id,
      ),
    );
    try {
      await _jobRepo.acceptJob(event.job.id);
    } catch (error) {
      emit(
        AcceptJobState(
          status: AcceptJobStatus.failure,
          error: error.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return;
    }
    emit(
      AcceptJobState(
        status: AcceptJobStatus.success,
        acceptedJob: event.job,
        client: await _loadClient(event.job.clientId),
      ),
    );
  }

  // The job is already mine at this point, so a failed lookup must not turn
  // it into an error. The screen shows that the contact is not available.
  Future<AppUser?> _loadClient(String clientId) async {
    try {
      return await _authRepo.getUser(clientId);
    } catch (_) {
      return null;
    }
  }
}
