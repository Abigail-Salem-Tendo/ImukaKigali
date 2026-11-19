import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imuka_kigali/domain/entities/vehicle.dart';
import 'package:imuka_kigali/domain/entities/vehicle_class.dart';
import 'package:imuka_kigali/domain/repositories/vehicle_repository.dart';

part 'driver_profile_event.dart';
part 'driver_profile_state.dart';

/// The logic of the driver profile. It loads the driver's vehicle and
/// creates, updates and deletes it through VehicleRepository.
class DriverProfileBloc extends Bloc<DriverProfileEvent, DriverProfileState> {
  /// Creates the bloc with nothing loaded and links each event to the
  /// method that handles it.
  DriverProfileBloc(this._repo) : super(const DriverProfileState()) {
    on<DriverProfileRequested>(_onRequested);
    on<DriverVehicleTypeChanged>(_onVehicleTypeChanged);
    on<DriverPlateNumberChanged>(_onPlateNumberChanged);
    on<DriverVehicleAdded>(_onVehicleAdded);
    on<DriverVehicleDeleted>(_onVehicleDeleted);
  }

  final VehicleRepository _repo;

  /// Loads the driver's vehicle from Firestore. The status becomes
  /// success (the vehicle may be null), or failure with a message.
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

  /// Changes the vehicle's type and sets its capacity to match the new
  /// type. Nothing happens if there is no vehicle or the type is the same.
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
        capacityKg: VehicleClasses.of(event.vehicleType).capacityKg,
      ),
      successMessage: 'Vehicle class updated.',
    );
  }

  /// Changes the vehicle's plate number after checking that it has a
  /// Rwanda plate's shape. A wrong plate shows an error and saves nothing.
  Future<void> _onPlateNumberChanged(
    DriverPlateNumberChanged event,
    Emitter<DriverProfileState> emit,
  ) async {
    final current = state.vehicle;
    if (current == null) {
      return;
    }
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

  /// Shows [updated] on the screen at once, then saves it in Firestore.
  /// If the save fails, it puts [previous] back and reports the error.
  Future<void> _saveChange(
    Emitter<DriverProfileState> emit, {
    required Vehicle previous,
    required Vehicle updated,
    required String successMessage,
  }) async {
    emit(state.copyWith(status: DriverProfileStatus.success, vehicle: updated));
    try {
      await _repo.updateVehicle(updated);
      emit(
        state.copyWith(
          status: DriverProfileStatus.success,
          message: successMessage,
        ),
      );
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

  /// Creates a vehicle for a driver who has none. isSaving is true while
  /// the save runs, so the button can show a spinner.
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

  /// Removes the vehicle from the screen at once, then deletes it from
  /// Firestore. If the delete fails, it brings the vehicle back.
  Future<void> _onVehicleDeleted(
    DriverVehicleDeleted event,
    Emitter<DriverProfileState> emit,
  ) async {
    final current = state.vehicle;
    if (current == null) {
      return;
    }
    emit(
      state.copyWith(status: DriverProfileStatus.success, clearVehicle: true),
    );
    try {
      await _repo.deleteVehicle(current.id);
      emit(
        state.copyWith(
          status: DriverProfileStatus.success,
          message: 'Vehicle removed.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: DriverProfileStatus.failure,
          vehicle: current,
          error: _readable(error),
        ),
      );
    }
  }

  /// Reports [message] as an error without changing the vehicle.
  /// The screen shows a snackbar when the status turns into failure, so a
  /// success state is emitted first to make sure that change happens even
  /// when the previous state was already a failure.
  void _fail(Emitter<DriverProfileState> emit, String message) {
    emit(state.copyWith(status: DriverProfileStatus.success));
    emit(state.copyWith(status: DriverProfileStatus.failure, error: message));
  }

  /// Removes the "Exception: " prefix so the driver sees a clean sentence.
  String _readable(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
