// Owner: Member 5
part of 'rating_bloc.dart';

enum RatingStatus { loading, ready, failure }

/// What just happened, so the screen can show one message for it.
enum RatingOutcome { created, updated, deleted }

class RatingState extends Equatable {
  const RatingState({
    this.status = RatingStatus.loading,
    this.request,
    this.existing,
    this.isClient = false,
    this.stars = 0,
    this.comment = '',
    this.saving = false,
    this.outcome,
    this.error,
  });

  final RatingStatus status;
  final MoveRequest? request;

  /// The rating already saved for this request, or null.
  final Rating? existing;

  /// true when the person using the app is the client of this request.
  final bool isClient;

  /// The stars picked on the screen. 0 means none yet.
  final int stars;
  final String comment;
  final bool saving;

  /// Set for one state after a save or a delete. Not carried over.
  final RatingOutcome? outcome;
  final String? error;

  /// Only the client rates, and only once the request is completed (paid).
  bool get canRate => isClient && request?.status == RequestStatus.completed;

  /// A new rating needs stars. An existing one needs a change.
  bool get canSubmit {
    if (!canRate || saving || stars < 1 || stars > 5) return false;
    final saved = existing;
    return saved == null || saved.stars != stars || saved.comment != comment;
  }

  /// [outcome] and [error] are not carried over, so each one is shown once.
  /// [clearExisting] is for after a delete.
  RatingState copyWith({
    RatingStatus? status,
    MoveRequest? request,
    Rating? existing,
    bool clearExisting = false,
    bool? isClient,
    int? stars,
    String? comment,
    bool? saving,
    RatingOutcome? outcome,
    String? error,
  }) => RatingState(
    status: status ?? this.status,
    request: request ?? this.request,
    existing: clearExisting ? null : existing ?? this.existing,
    isClient: isClient ?? this.isClient,
    stars: stars ?? this.stars,
    comment: comment ?? this.comment,
    saving: saving ?? this.saving,
    outcome: outcome,
    error: error,
  );

  @override
  List<Object?> get props => [
    status,
    request,
    existing,
    isClient,
    stars,
    comment,
    saving,
    outcome,
    error,
  ];
}
