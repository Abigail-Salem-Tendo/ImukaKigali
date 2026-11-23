import 'package:imuka_kigali/domain/entities/rating.dart';
import 'package:imuka_kigali/domain/repositories/rating_repository.dart';

/// In-memory RatingRepository so blocs and screens can be tested without
/// Firebase. It follows the same rules as the real one: one rating per request.
class FakeRatingRepository implements RatingRepository {
  Rating? saved;
  String? failWith;
  int createCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;

  void _maybeFail() {
    if (failWith != null) throw Exception(failWith);
  }

  @override
  Future<String> createRating(Rating rating) async {
    createCalls++;
    _maybeFail();
    saved = rating;
    return rating.requestId;
  }

  @override
  Future<Rating?> getRating(String requestId) async {
    _maybeFail();
    return saved;
  }

  @override
  Future<void> updateRating(Rating rating) async {
    updateCalls++;
    _maybeFail();
    saved = rating;
  }

  @override
  Future<void> deleteRating(String ratingId) async {
    deleteCalls++;
    _maybeFail();
    saved = null;
  }
}
