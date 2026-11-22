// Owner: Member 5
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/domain/entities/app_user.dart';
import 'package:imuka_kigali/domain/entities/move_request.dart';
import 'package:imuka_kigali/domain/entities/vehicle.dart';
import 'package:imuka_kigali/domain/repositories/auth_repository.dart';
import 'package:imuka_kigali/domain/repositories/request_repository.dart';
import 'package:imuka_kigali/domain/repositories/vehicle_repository.dart';

part 'driver_contact_event.dart';
part 'driver_contact_state.dart';

/// Shows the client who accepted their request: the driver's name and phone,
/// their vehicle and the fixed price. With no bidding there is nothing to
/// negotiate, so the two just agree the details by phone.
class DriverContactBloc extends Bloc<DriverContactEvent, DriverContactState> {
  DriverContactBloc(this._requests, this._auth, this._vehicles, this.requestId)
    : super(const DriverContactState()) {
    on<DriverContactStarted>(_onStarted);
    on<DriverDetailsRequested>(_onDetailsRequested);
  }

  final RequestRepository _requests;
  final AuthRepository _auth;
  final VehicleRepository _vehicles;
  final String requestId;

  /// The driver whose details are loaded (or loading), so a request update
  /// does not load them again.
  String? _driverIdRequested;

  Future<void> _onStarted(
    DriverContactStarted event,
    Emitter<DriverContactState> emit,
  ) {
    return emit.forEach<MoveRequest?>(
      _requests.watchRequest(requestId),
      onData: _fromRequest,
      onError: (error, _) => state.copyWith(
        status: DriverContactStatus.failure,
        error: _message(error),
      ),
    );
  }

  DriverContactState _fromRequest(MoveRequest? request) {
    if (request == null) {
      return state.copyWith(
        status: DriverContactStatus.failure,
        error: 'Request not found',
      );
    }
    final driverId = request.driverId;
    if (driverId.isNotEmpty && driverId != _driverIdRequested) {
      _driverIdRequested = driverId;
      add(DriverDetailsRequested(driverId));
    }
    return state.copyWith(status: DriverContactStatus.ready, request: request);
  }

  Future<void> _onDetailsRequested(
    DriverDetailsRequested event,
    Emitter<DriverContactState> emit,
  ) async {
    emit(state.copyWith(detailsStatus: DriverDetailsStatus.loading));

    // The profile and the vehicle load separately, so one failing still
    // shows the other.
    AppUser? driver;
    Vehicle? vehicle;
    String? problem;
    try {
      driver = await _auth.getUser(event.driverId);
    } catch (e) {
      problem = _message(e);
    }
    try {
      vehicle = await _vehicles.getVehicle(event.driverId);
    } catch (e) {
      problem ??= _message(e);
    }

    emit(
      state.copyWith(
        detailsStatus: problem == null
            ? DriverDetailsStatus.loaded
            : DriverDetailsStatus.failure,
        driver: driver,
        vehicle: vehicle,
        error: problem,
      ),
    );
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
