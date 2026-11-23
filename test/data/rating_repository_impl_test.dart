import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/data/repositories/rating_repository_impl.dart';
import 'package:imuka_kigali/domain/entities/rating.dart';

import '../helpers/fake_firestore.dart';

/// Unit tests for RatingRepositoryImpl, using an in-memory Firestore.
/// Run them with: flutter test test/data/rating_repository_impl_test.dart
void main() {
  late FakeFirestore db;
  late RatingRepositoryImpl repo;

  Rating rating({
    String id = '',
    String requestId = 'r1',
    int stars = 5,
    String comment = 'Careful with the sofa',
  }) => Rating(
    id: id,
    requestId: requestId,
    clientId: 'client1',
    driverId: 'driver1',
    stars: stars,
    comment: comment,
    createdAt: DateTime(2026),
  );

  Matcher throwsMessage(String message) =>
      throwsA(predicate((e) => e.toString() == 'Exception: $message'));

  setUp(() {
    db = FakeFirestore();
    repo = RatingRepositoryImpl(db: db);
  });

  group('createRating', () {
    test(
      'saves the rating in "ratings" with the request id as its id',
      () async {
        final id = await repo.createRating(rating());

        expect(id, 'r1');
        final saved = db.read(Collections.ratings, 'r1')!;
        expect(saved[Fields.requestId], 'r1');
        expect(saved[Fields.clientId], 'client1');
        expect(saved[Fields.driverId], 'driver1');
        expect(saved[Fields.stars], 5);
        expect(saved[Fields.comment], 'Careful with the sofa');
      },
    );

    test('createdAt is the server time', () async {
      await repo.createRating(rating());

      expect(
        db.read(Collections.ratings, 'r1')![Fields.createdAt],
        isA<FieldValue>(),
      );
    });

    test('rating the same request twice is refused', () async {
      await repo.createRating(rating());

      await expectLater(
        repo.createRating(rating(stars: 1)),
        throwsMessage('This request has already been rated'),
      );
      expect(db.read(Collections.ratings, 'r1')![Fields.stars], 5);
    });

    test('stars outside 1 to 5 are refused and nothing is saved', () async {
      for (final stars in [0, 6, -1]) {
        await expectLater(
          repo.createRating(rating(stars: stars)),
          throwsMessage('Choose from 1 to 5 stars'),
        );
      }
      expect(db.store[Collections.ratings], isNull);
    });

    test('a Firestore error becomes a readable Exception', () async {
      db.failWith = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'You are not allowed to rate this request',
      );

      await expectLater(
        repo.createRating(rating()),
        throwsMessage('You are not allowed to rate this request'),
      );
    });
  });

  group('getRating', () {
    test('returns null when the request has no rating yet', () async {
      expect(await repo.getRating('r1'), isNull);
    });

    test('returns the rating saved for that request', () async {
      await repo.createRating(rating(stars: 4, comment: 'On time'));

      final saved = await repo.getRating('r1');

      expect(saved!.id, 'r1');
      expect(saved.stars, 4);
      expect(saved.comment, 'On time');
      expect(saved.clientId, 'client1');
      expect(saved.driverId, 'driver1');
    });

    test('a Firestore error becomes a readable Exception', () async {
      db.failWith = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
        message: 'No internet connection',
      );

      await expectLater(
        repo.getRating('r1'),
        throwsMessage('No internet connection'),
      );
    });
  });

  group('updateRating', () {
    test('changes the stars and the comment', () async {
      await repo.createRating(rating());

      await repo.updateRating(
        rating(id: 'r1', stars: 2, comment: 'Late, but polite'),
      );

      final saved = db.read(Collections.ratings, 'r1')!;
      expect(saved[Fields.stars], 2);
      expect(saved[Fields.comment], 'Late, but polite');
    });

    test('never changes who rated whom', () async {
      await repo.createRating(rating());

      await repo.updateRating(
        Rating(
          id: 'r1',
          requestId: 'other-request',
          clientId: 'someone-else',
          driverId: 'another-driver',
          stars: 3,
          comment: 'x',
          createdAt: DateTime(2030),
        ),
      );

      final saved = db.read(Collections.ratings, 'r1')!;
      expect(saved[Fields.requestId], 'r1');
      expect(saved[Fields.clientId], 'client1');
      expect(saved[Fields.driverId], 'driver1');
    });

    test('stars outside 1 to 5 are refused', () async {
      await repo.createRating(rating());

      await expectLater(
        repo.updateRating(rating(id: 'r1', stars: 9)),
        throwsMessage('Choose from 1 to 5 stars'),
      );
      expect(db.read(Collections.ratings, 'r1')![Fields.stars], 5);
    });

    test('updating a rating that does not exist says so', () async {
      await expectLater(
        repo.updateRating(rating(id: 'missing')),
        throwsMessage('This rating does not exist'),
      );
    });
  });

  group('deleteRating', () {
    test('removes the rating, so the request can be rated again', () async {
      await repo.createRating(rating());

      await repo.deleteRating('r1');

      expect(await repo.getRating('r1'), isNull);
      expect(await repo.createRating(rating(stars: 3)), 'r1');
    });

    test('a Firestore error becomes a readable Exception', () async {
      db.failWith = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'You are not allowed to delete this rating',
      );

      await expectLater(
        repo.deleteRating('r1'),
        throwsMessage('You are not allowed to delete this rating'),
      );
    });
  });
}
