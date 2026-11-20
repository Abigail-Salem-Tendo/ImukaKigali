// Owner: Member 3
// Bloc: CreateRequestBloc - shared by where_from_to and item_details (template: ARCHITECTURE.md Part 5)
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/core/constants/kigali_areas.dart';
import 'package:imuka_kigali/core/utils/fare_calculator.dart';
import 'package:imuka_kigali/domain/entities/move_request.dart';
import 'package:imuka_kigali/domain/repositories/request_repository.dart';

part 'create_request_event.dart';
part 'create_request_state.dart';

/// Shared by where_from_to and item_details (provided by a ShellRoute).
class CreateRequestBloc extends Bloc<CreateRequestEvent, CreateRequestState> {
  CreateRequestBloc(this._repo) : super(const CreateRequestState()) {
    on<PickupSelected>((e, emit) => emit(state.copyWith(pickup: e.area)));
    on<DropoffSelected>((e, emit) => emit(state.copyWith(dropoff: e.area)));
    on<VehicleTypeSelected>(
      (e, emit) => emit(state.copyWith(vehicleType: e.vehicleType)),
    );
    on<ItemDescriptionChanged>(
      (e, emit) => emit(state.copyWith(itemDescription: e.description)),
    );
    on<RequestSubmitted>(_onSubmitted);
  }

  final RequestRepository _repo;

  Future<void> _onSubmitted(
    RequestSubmitted e,
    Emitter<CreateRequestState> emit,
  ) async {
    final pickup = state.pickup;
    final dropoff = state.dropoff;
    final vehicleType = state.vehicleType;
    if (!state.canSubmit ||
        pickup == null ||
        dropoff == null ||
        vehicleType == null) {
      return;
    }

    emit(state.copyWith(status: CreateRequestStatus.submitting));
    try {
      final fare = FareCalculator.calculate(
        pickup: pickup,
        dropoff: dropoff,
        vehicleType: vehicleType,
      );
      final id = await _repo.createRequest(
        MoveRequest(
          id: '',
          clientId: e.clientId,
          driverId: '',
          pickupLocation: pickup.name,
          dropoffLocation: dropoff.name,
          itemDescription: state.itemDescription.trim(),
          vehicleType: vehicleType,
          estimatedMinutes: fare.estimatedMinutes,
          proposedAmount: fare.proposedAmount,
          status: RequestStatus.open,
          clientConfirmed: false,
          driverConfirmed: false,
          createdAt: DateTime.now(),
        ),
      );
      emit(state.copyWith(status: CreateRequestStatus.success, requestId: id));
    } catch (ex) {
      emit(
        state.copyWith(
          status: CreateRequestStatus.failure,
          error: ex.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }
}
