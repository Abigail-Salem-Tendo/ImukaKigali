// Owner: Member 4
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imuka_kigali/domain/entities/move_request.dart';
import 'package:imuka_kigali/domain/entities/vehicle.dart';
import 'package:imuka_kigali/domain/repositories/driver_job_repository.dart';
import 'package:imuka_kigali/domain/repositories/vehicle_repository.dart';

part 'open_jobs_event.dart';
part 'open_jobs_state.dart';

class OpenJobsBloc extends Bloc<OpenJobsEvent, OpenJobsState> {
  OpenJobsBloc(this._jobRepo, this._vehicleRepo)
    : super(const OpenJobsState()) {
    on<OpenJobsStarted>(_onStarted);
  }

  final DriverJobRepository _jobRepo;
  final VehicleRepository _vehicleRepo;

  Future<void> _onStarted(
    OpenJobsStarted event,
    Emitter<OpenJobsState> emit,
  ) async {
    if (event.driverId.isEmpty) {
      emit(_failed('Please sign in again to see open jobs'));
      return;
    }
    emit(state.copyWith(status: OpenJobsStatus.loading));

    // A driver only sees jobs for their own vehicle type, so the vehicle
    // is loaded before the list is watched.
    final Vehicle? vehicle;
    try {
      vehicle = await _vehicleRepo.getVehicle(event.driverId);
    } catch (error) {
      emit(_failed(error));
      return;
    }
    if (vehicle == null) {
      emit(state.copyWith(status: OpenJobsStatus.noVehicle));
      return;
    }

    await emit.forEach<List<MoveRequest>>(
      _jobRepo.watchOpenJobs(vehicle.vehicleType),
      onData: (jobs) => state.copyWith(
        status: OpenJobsStatus.success,
        vehicle: vehicle,
        jobs: jobs,
      ),
      onError: (error, _) => _failed(error),
    );
  }

  OpenJobsState _failed(Object error) => state.copyWith(
    status: OpenJobsStatus.failure,
    error: error.toString().replaceFirst('Exception: ', ''),
  );
}
