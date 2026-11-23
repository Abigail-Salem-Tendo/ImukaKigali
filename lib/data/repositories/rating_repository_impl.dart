// Owner: Member 5
// RatingRepositoryImpl implements RatingRepository using the 'ratings' collection.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/domain/entities/rating.dart';
import 'package:imuka_kigali/domain/repositories/rating_repository.dart';

/// The Firestore code for ratings. Only this layer imports Firebase.
class RatingRepositoryImpl implements RatingRepository {
  RatingRepositoryImpl({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _ratings =>
      _db.collection(Collections.ratings);

  // The document id is the request id, and the check runs in a transaction,
  // so one request can never get two ratings.
  @override
  Future<String> createRating(Rating rating) async {
    _checkStars(rating.stars);
    final ref = _ratings.doc(rating.requestId);
    try {
      await _db.runTransaction((transaction) async {
        final existing = await transaction.get(ref);
        if (existing.exists) {
          throw Exception('This request has already been rated');
        }
        transaction.set(ref, {
          ...rating.toMap(),
          // The server time, so a wrong phone clock cannot change it.
          Fields.createdAt: FieldValue.serverTimestamp(),
        });
      });
      return ref.id;
    } on FirebaseException catch (e) {
      throw Exception(e.message ?? 'Could not save the rating');
    }
  }

  @override
  Future<Rating?> getRating(String requestId) async {
    try {
      final doc = await _ratings.doc(requestId).get();
      final data = doc.data();
      return data == null ? null : Rating.fromMap(doc.id, data);
    } on FirebaseException catch (e) {
      throw Exception(e.message ?? 'Could not load the rating');
    }
  }

  @override
  Future<void> updateRating(Rating rating) async {
    _checkStars(rating.stars);
    try {
      // Only the stars and the comment can change. Who rated whom, and when,
      // stays as it was.
      await _ratings.doc(rating.id).update({
        Fields.stars: rating.stars,
        Fields.comment: rating.comment,
      });
    } on FirebaseException catch (e) {
      throw Exception(
        e.code == 'not-found'
            ? 'This rating does not exist'
            : e.message ?? 'Could not update the rating',
      );
    }
  }

  @override
  Future<void> deleteRating(String ratingId) async {
    try {
      await _ratings.doc(ratingId).delete();
    } on FirebaseException catch (e) {
      throw Exception(e.message ?? 'Could not delete the rating');
    }
  }

  void _checkStars(int stars) {
    if (stars < 1 || stars > 5) {
      throw Exception('Choose from 1 to 5 stars');
    }
  }
}
