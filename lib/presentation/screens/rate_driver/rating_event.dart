// Owner: Member 5
part of 'rating_bloc.dart';

sealed class RatingEvent extends Equatable {
  const RatingEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the request and the rating that may already exist for it.
class RatingStarted extends RatingEvent {
  const RatingStarted();
}

/// The client tapped a star (1 to 5).
class StarsSelected extends RatingEvent {
  const StarsSelected(this.stars);

  final int stars;

  @override
  List<Object?> get props => [stars];
}

class CommentChanged extends RatingEvent {
  const CommentChanged(this.comment);

  final String comment;

  @override
  List<Object?> get props => [comment];
}

/// Saves the rating: creates it, or updates it if there already is one.
class RatingSubmitted extends RatingEvent {
  const RatingSubmitted();
}

class RatingDeleted extends RatingEvent {
  const RatingDeleted();
}
