import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/domain/entities/rating.dart';

/// Unit tests for the Rating entity: what goes into Firestore and what
/// comes back out must match the ERD.
void main() {
  final createdAt = DateTime(2026, 11, 22, 9, 15);

  test('toMap uses the field names from the ERD and no id', () {
    final rating = Rating(
      id: 'r1',
      requestId: 'r1',
      clientId: 'client1',
      driverId: 'driver1',
      stars: 5,
      comment: 'Careful with the sofa',
      createdAt: createdAt,
    );

    expect(rating.toMap(), {
      Fields.requestId: 'r1',
      Fields.clientId: 'client1',
      Fields.driverId: 'driver1',
      Fields.stars: 5,
      Fields.comment: 'Careful with the sofa',
      Fields.createdAt: createdAt,
    });
  });

  test('fromMap turns a Firestore map back into the same rating', () {
    final rating = Rating.fromMap('r1', {
      Fields.requestId: 'r1',
      Fields.clientId: 'client1',
      Fields.driverId: 'driver1',
      Fields.stars: 4.0, // a number from Firestore may arrive as a double
      Fields.comment: 'On time',
      Fields.createdAt: createdAt,
    });

    expect(rating.id, 'r1');
    expect(rating.stars, 4);
    expect(rating.comment, 'On time');
    expect(rating.createdAt, createdAt);
  });

  test('a rating with missing fields has no stars and an empty comment', () {
    final rating = Rating.fromMap('r2', {Fields.requestId: 'r2'});

    expect(rating.stars, 0);
    expect(rating.comment, '');
    expect(rating.clientId, '');
  });

  test('two ratings with the same values are equal', () {
    Rating make() => Rating(
      id: 'r1',
      requestId: 'r1',
      clientId: 'c',
      driverId: 'd',
      stars: 3,
      comment: '',
      createdAt: createdAt,
    );

    expect(make(), make());
  });
}
