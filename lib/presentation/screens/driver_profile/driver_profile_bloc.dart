
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/vehicle.dart';
import '../../../domain/repositories/vehicle_repository.dart';

part 'driver_profile_event.dart';
part 'driver_profile_state.dart';

class DriverProfileBloc extends Bloc<DriverProfileEvent, DriverProfileState> {
  DriverProfileBloc(this._repo) : super(const DriverProfileState()) {
    on<DriverProfileRequested>(_onRequested);
    on<DriverVehicleTypeChanged>(_onVehicleTypeChanged);
    on<DriverPlateNumberChanged>(_onPlateNumberChanged);
    on<DriverHubToggled>(_onHubToggled);
    on<DriverVehicleAdded>(_onVehicleAdded);
    on<DriverVehicleDeleted>(_onVehicleDeleted);
  }

  final VehicleRepository _repo;

  /// Remembers the hubs of a deleted vehicle, so a re-added vehicle keeps them.
  List<String> _lastHubs = const [];

  // ------------------------------- READ -------------------------------

  Future<void> _onRequested(
      DriverProfileRequested event,
      Emitter<DriverProfileState> emit,
      ) async {
    emit(state.copyWith(status: DriverProfileStatus.loading));
    try {
      final vehicle = await _repo.getVehicle(event.driverId);
      emit(
        state.copyWith(
          status: DriverProfileStatus.success,
          hasLoaded: true,
          vehicle: vehicle,
          clearVehicle: vehicle == null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: DriverProfileStatus.failure,
          error: _readable(error),
        ),
      );
    }
  }

  // ------------------------------ UPDATE ------------------------------

  Future<void> _onVehicleTypeChanged(
      DriverVehicleTypeChanged event,
      Emitter<DriverProfileState> emit,
      ) async {
    final current = state.vehicle;
    if (current == null || current.vehicleType == event.vehicleType) {
      return;
    }
    await _saveChange(
      emit,
      previous: current,
      updated: current.copyWith(
        vehicleType: event.vehicleType,
        capacityKg: event.vehicleType.capacityKg,
      ),
      successMessage: 'Vehicle class updated.',
    );
  }

  Future<void> _onPlateNumberChanged(
      DriverPlateNumberChanged event,
      Emitter<DriverProfileState> emit,
      ) async {
    final current = state.vehicle;
    if (current == null) {
      return;
    }
    // Check the plate here too, not only in the dialog. The bloc is the
    // place where the rules live.
    if (!isValidRwandaPlate(event.plateNumber)) {
      _fail(emit, 'Enter a Rwanda plate like RAD 428 E.');
      return;
    }
    final plate = formatRwandaPlate(event.plateNumber);
    if (plate == current.plateNumber) {
      return;
    }
    await _saveChange(
      emit,
      previous: current,
      updated: current.copyWith(plateNumber: plate),
      successMessage: 'Plate number updated.',
    );
  }

  Future<void> _onHubToggled(
      DriverHubToggled event,
      Emitter<DriverProfileState> emit,
      ) async {
    final current = state.vehicle;
    if (current == null) {
      return;
    }
    final hubs = [...current.operatingHubs];
    if (hubs.contains(event.hub)) {
      if (hubs.length <= 2) {
        _fail(emit, 'Keep at least 2 hubs so you still get nearby moves.');
        return;
      }
      hubs.remove(event.hub);
    } else {
      hubs.add(event.hub);
    }
    // No success message here: a snackbar on every chip tap would be noisy.
    await _saveChange(
      emit,
      previous: current,
      updated: current.copyWith(operatingHubs: hubs),
    );
  }

  /// Shows the change AT ONCE (so the app feels instant), then saves it.
  /// If saving fails, it puts the old vehicle back and shows an error.
  Future<void> _saveChange(
      Emitter<DriverProfileState> emit, {
        required Vehicle previous,
        required Vehicle updated,
        String? successMessage,
      }) async {
    emit(
      state.copyWith(status: DriverProfileStatus.success, vehicle: updated),
    );
    try {
      await _repo.updateVehicle(updated);
      if (successMessage != null) {
        emit(
          state.copyWith(
            status: DriverProfileStatus.success,
            message: successMessage,
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: DriverProfileStatus.failure,
          vehicle: previous,
          error: _readable(error),
        ),
      );
    }
  }

  // ------------------------------ CREATE ------------------------------

  Future<void> _onVehicleAdded(
      DriverVehicleAdded event,
      Emitter<DriverProfileState> emit,
      ) async {
    if (state.vehicle != null || state.isSaving) {
      return;
    }
    emit(state.copyWith(isSaving: true));
    try {
      final vehicle = await _repo.addVehicle(
        vehicleType: event.vehicleType,
        plateNumber: formatRwandaPlate(event.plateNumber),
        operatingHubs: _lastHubs,
      );
      emit(
        state.copyWith(
          status: DriverProfileStatus.success,
          isSaving: false,
          vehicle: vehicle,
          message: 'Vehicle added.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: DriverProfileStatus.failure,
          isSaving: false,
          error: _readable(error),
        ),
      );
    }
  }

  // ------------------------------ DELETE ------------------------------

  Future<void> _onVehicleDeleted(
      DriverVehicleDeleted event,
      Emitter<DriverProfileState> emit,
      ) async {
    final current = state.vehicle;
    if (current == null) {
      return;
    }
    _lastHubs = current.operatingHubs;
    // Remove it from the screen at once...
    emit(
      state.copyWith(status: DriverProfileStatus.success, clearVehicle: true),
    );
    try {
      // ...then from Firestore.
      await _repo.deleteVehicle(current.id);
      emit(
        state.copyWith(
          status: DriverProfileStatus.success,
          message: 'Vehicle removed.',
        ),
      );
    } catch (error) {
      // Deleting failed, so bring the vehicle back.
      emit(
        state.copyWith(
          status: DriverProfileStatus.failure,
          vehicle: current,
          error: _readable(error),
        ),
      );
    }
  }

  // ------------------------------ HELPERS -----------------------------

  /// Shows [message] in a snackbar without changing anything.
  ///
  /// The screen shows a snackbar when the status CHANGES to failure.
  /// Emitting "success" first makes sure that change happens, even if the
  /// last state was already a failure (e.g. two wrong taps in a row).
  void _fail(Emitter<DriverProfileState> emit, String message) {
    emit(state.copyWith(status: DriverProfileStatus.success));
    emit(state.copyWith(status: DriverProfileStatus.failure, error: message));
  }

  /// "Exception: No internet" -> "No internet"
  String _readable(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
