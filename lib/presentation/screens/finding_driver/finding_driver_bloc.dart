import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/domain/entities/move_request.dart';
import 'package:imuka_kigali/domain/repositories/request_repository.dart';

part 'finding_driver_event.dart';
part 'finding_driver_state.dart';

/// Watches one request while the client waits for a driver.
/// open -> searching, accepted -> accepted, cancelled -> cancelled.
class FindingDriverBloc extends Bloc<FindingDriverEvent, FindingDriverState> {
  FindingDriverBloc(this._repo, this.requestId)
    : super(const FindingDriverState()) {
    on<FindingDriverStarted>(_onStarted);
    on<CancelRequested>(_onCancelRequested);
  }

  final RequestRepository _repo;
  final String requestId;

  Future<void> _onStarted(
    FindingDriverStarted event,
    Emitter<FindingDriverState> emit,
  ) {
    return emit.forEach<MoveRequest?>(
      _repo.watchRequest(requestId),
      onData: _fromRequest,
      onError: (error, _) => state.copyWith(
        status: FindingDriverStatus.failure,
        error: _message(error),
      ),
    );
  }

  FindingDriverState _fromRequest(MoveRequest? request) {
    if (request == null) {
      return state.copyWith(
        status: FindingDriverStatus.failure,
        error: 'Request not found',
      );
    }
    final status = switch (request.status) {
      RequestStatus.open => FindingDriverStatus.searching,
      RequestStatus.cancelled => FindingDriverStatus.cancelled,
      _ => FindingDriverStatus.accepted,
    };
    return state.copyWith(status: status, request: request);
  }

  // On success the live stream reports `cancelled`, which moves the screen on.
  Future<void> _onCancelRequested(
    CancelRequested event,
    Emitter<FindingDriverState> emit,
  ) async {
    emit(state.copyWith(cancelling: true));
    try {
      await _repo.cancelRequest(requestId);
      emit(state.copyWith(cancelling: false));
    } catch (e) {
      emit(state.copyWith(cancelling: false, error: _message(e)));
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
