// Owner: Member 5
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/domain/entities/move_request.dart';
import 'package:imuka_kigali/domain/entities/rating.dart';
import 'package:imuka_kigali/domain/repositories/rating_repository.dart';
import 'package:imuka_kigali/domain/repositories/request_repository.dart';

part 'rating_event.dart';
part 'rating_state.dart';

/// The client rates the driver after the deal: create, change or delete the
/// one rating of a request.
class RatingBloc extends Bloc<RatingEvent, RatingState> {
  /// [viewerId] is the uid of the person using the app (from AuthBloc).
  RatingBloc(this._ratings, this._requests, this.requestId, this.viewerId)
    : super(const RatingState()) {
    on<RatingStarted>(_onStarted);
    on<StarsSelected>(
      (event, emit) => emit(state.copyWith(stars: event.stars)),
    );
    on<CommentChanged>(
      (event, emit) => emit(state.copyWith(comment: event.comment)),
    );
    on<RatingSubmitted>(_onSubmitted);
    on<RatingDeleted>(_onDeleted);
  }

  final RatingRepository _ratings;
  final RequestRepository _requests;
  final String requestId;
  final String viewerId;

  Future<void> _onStarted(
    RatingStarted event,
    Emitter<RatingState> emit,
  ) async {
    emit(state.copyWith(status: RatingStatus.loading));
    try {
      final request = await _requests.getRequest(requestId);
      if (request == null) {
        emit(
          state.copyWith(
            status: RatingStatus.failure,
            error: 'Request not found',
          ),
        );
        return;
      }
      final existing = await _ratings.getRating(requestId);
      emit(
        state.copyWith(
          status: RatingStatus.ready,
          request: request,
          existing: existing,
          isClient: request.clientId == viewerId,
          // An existing rating is shown so it can be changed.
          stars: existing?.stars,
          comment: existing?.comment,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: RatingStatus.failure, error: _message(e)));
    }
  }

  Future<void> _onSubmitted(
    RatingSubmitted event,
    Emitter<RatingState> emit,
  ) async {
    final request = state.request;
    if (request == null || state.saving) return;
    if (!state.isClient) {
      emit(state.copyWith(error: 'Only the client can rate the driver'));
      return;
    }
    if (request.status != RequestStatus.completed) {
      emit(state.copyWith(error: 'You can rate after the payment is complete'));
      return;
    }
    if (state.stars < 1 || state.stars > 5) {
      emit(state.copyWith(error: 'Choose from 1 to 5 stars'));
      return;
    }

    // Nothing to save: already saving, or the rating has not changed.
    if (!state.canSubmit) return;

    emit(state.copyWith(saving: true));
    final saved = state.existing;
    final rating = Rating(
      id: requestId,
      requestId: requestId,
      clientId: request.clientId,
      driverId: request.driverId,
      stars: state.stars,
      comment: state.comment.trim(),
      createdAt: saved?.createdAt ?? DateTime.now(),
    );
    try {
      if (saved == null) {
        await _ratings.createRating(rating);
      } else {
        await _ratings.updateRating(rating);
      }
      emit(
        state.copyWith(
          saving: false,
          existing: rating,
          comment: rating.comment,
          outcome: saved == null
              ? RatingOutcome.created
              : RatingOutcome.updated,
        ),
      );
    } catch (e) {
      emit(state.copyWith(saving: false, error: _message(e)));
    }
  }

  Future<void> _onDeleted(
    RatingDeleted event,
    Emitter<RatingState> emit,
  ) async {
    final saved = state.existing;
    if (saved == null || state.saving) return;

    emit(state.copyWith(saving: true));
    try {
      await _ratings.deleteRating(saved.id);
      emit(
        state.copyWith(
          saving: false,
          clearExisting: true,
          stars: 0,
          comment: '',
          outcome: RatingOutcome.deleted,
        ),
      );
    } catch (e) {
      emit(state.copyWith(saving: false, error: _message(e)));
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
