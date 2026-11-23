// Owner: Member 4
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/domain/entities/move_request.dart';
import 'package:imuka_kigali/domain/entities/vehicle.dart';
import 'package:imuka_kigali/domain/repositories/driver_job_repository.dart';
import 'package:imuka_kigali/domain/repositories/vehicle_repository.dart';

part 'driver_home_event.dart';
part 'driver_home_state.dart';

class DriverHomeBloc extends Bloc<DriverHomeEvent, DriverHomeState> {
  DriverHomeBloc(this._jobRepo, this._vehicleRepo)
    : super(const DriverHomeState()) {
    on<DriverHomeStarted>(_onStarted);
  }

  final DriverJobRepository _jobRepo;
  final VehicleRepository _vehicleRepo;

  Future<void> _onStarted(
    DriverHomeStarted event,
    Emitter<DriverHomeState> emit,
  ) async {
    if (event.driverId.isEmpty) {
      emit(_failed('Please sign in again to see your jobs'));
      return;
    }
    emit(const DriverHomeState(status: DriverHomeStatus.loading));

    final Vehicle? vehicle;
    try {
      vehicle = await _vehicleRepo.getVehicle(event.driverId);
    } catch (error) {
      emit(_failed(error));
      return;
    }
    if (vehicle == null) {
      emit(state.copyWith(status: DriverHomeStatus.noVehicle));
      return;
    }
    emit(state.copyWith(status: DriverHomeStatus.success, vehicle: vehicle));

    // Both lists stay live while the screen is open, so they are watched
    // side by side instead of one after the other.
    await Future.wait([
      emit.forEach<List<MoveRequest>>(
        _jobRepo.watchOpenJobs(vehicle.vehicleType),
        onData: (jobs) => state.copyWith(openJobCount: jobs.length),
        onError: (error, _) => _failed(error),
      ),
      emit.forEach<List<MoveRequest>>(
        _jobRepo.watchMyJobs(event.driverId),
        onData: (jobs) => state.copyWith(myJobs: jobs),
        onError: (error, _) => _failed(error),
      ),
    ]);
  }

  DriverHomeState _failed(Object error) => state.copyWith(
    status: DriverHomeStatus.failure,
    error: error.toString().replaceFirst('Exception: ', ''),
  );
}
