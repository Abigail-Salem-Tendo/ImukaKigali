// Owner: Member 5
// What the app can do with the 'ratings' collection.
// No Firebase here: blocs depend on this, not on the Firebase code.
import 'package:imuka_kigali/domain/entities/rating.dart';

abstract class RatingRepository {
  /// Saves the client's rating of a request and returns its id.
  /// A request has only one rating (the id is the request id), so rating it a
  /// second time throws an Exception. Use [updateRating] to change it.
  /// [Rating.stars] must be from 1 to 5.
  Future<String> createRating(Rating rating);

  /// The rating of one request, read once. Returns null if there is none yet.
  Future<Rating?> getRating(String requestId);

  /// Changes the stars and the comment of an existing rating.
  /// Throws an Exception with a readable message if it does not exist.
  Future<void> updateRating(Rating rating);

  /// Removes the rating with the id [ratingId] (the request id).
  Future<void> deleteRating(String ratingId);
}
