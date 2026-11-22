import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/domain/entities/rating.dart';
import 'package:imuka_kigali/presentation/screens/rate_driver/rating_bloc.dart';

import '../helpers/fake_rating_repository.dart';
import '../helpers/fake_request_repository.dart';

const _clientId = 'client1';
const _driverId = 'driver1';

void main() {
  late FakeRequestRepository requests;
  late FakeRatingRepository ratings;
  late RatingBloc bloc;

  RatingBloc build(String viewerId) =>
      RatingBloc(ratings, requests, 'r1', viewerId);

  /// Starts the bloc and waits until the request and rating are loaded.
  Future<void> start() async {
    bloc.add(const RatingStarted());
    await bloc.stream.firstWhere((s) => s.status != RatingStatus.loading);
  }

  /// Picks stars and waits for the bloc to have them.
  Future<void> pick(int stars) async {
    bloc.add(StarsSelected(stars));
    await bloc.stream.firstWhere((s) => s.stars == stars);
  }

  setUp(() {
    requests = FakeRequestRepository(
      dealRequest(status: RequestStatus.completed),
    );
    ratings = FakeRatingRepository();
  });

  tearDown(() => bloc.close());

  group('starting', () {
    test('starts loading', () {
      bloc = build(_clientId);
      expect(bloc.state.status, RatingStatus.loading);
    });

    test('a new rating starts with no stars', () async {
      bloc = build(_clientId);
      await start();

      expect(bloc.state.status, RatingStatus.ready);
      expect(bloc.state.isClient, isTrue);
      expect(bloc.state.existing, isNull);
      expect(bloc.state.stars, 0);
      expect(bloc.state.canRate, isTrue);
      expect(bloc.state.canSubmit, isFalse);
    });

    test('an existing rating is loaded so it can be changed', () async {
      ratings.saved = Rating(
        id: 'r1',
        requestId: 'r1',
        clientId: _clientId,
        driverId: _driverId,
        stars: 4,
        comment: 'On time',
        createdAt: DateTime(2026),
      );
      bloc = build(_clientId);
      await start();

      expect(bloc.state.existing!.stars, 4);
      expect(bloc.state.stars, 4);
      expect(bloc.state.comment, 'On time');
      expect(bloc.state.canSubmit, isFalse); // nothing changed yet
    });

    test('a missing request is a failure', () async {
      requests = FakeRequestRepository(null);
      bloc = build(_clientId);
      await start();

      expect(bloc.state.status, RatingStatus.failure);
      expect(bloc.state.error, 'Request not found');
    });

    test('a Firestore error is shown as a readable failure', () async {
      requests.failGetWith = 'No internet connection';
      bloc = build(_clientId);
      await start();

      expect(bloc.state.status, RatingStatus.failure);
      expect(bloc.state.error, 'No internet connection');
    });
  });

  group('who can rate and when', () {
    test('the driver cannot rate', () async {
      bloc = build(_driverId);
      await start();

      expect(bloc.state.canRate, isFalse);
      bloc.add(const RatingSubmitted());
      final failed = await bloc.stream.firstWhere((s) => s.error != null);

      expect(failed.error, 'Only the client can rate the driver');
      expect(ratings.createCalls, 0);
    });

    test('a request that is not completed cannot be rated yet', () async {
      requests = FakeRequestRepository(dealRequest());
      bloc = build(_clientId);
      await start();
      await pick(5);

      expect(bloc.state.canRate, isFalse);
      bloc.add(const RatingSubmitted());
      final failed = await bloc.stream.firstWhere((s) => s.error != null);

      expect(failed.error, 'You can rate after the payment is complete');
      expect(ratings.createCalls, 0);
    });

    test('submitting without stars is refused', () async {
      bloc = build(_clientId);
      await start();

      bloc.add(const RatingSubmitted());
      final failed = await bloc.stream.firstWhere((s) => s.error != null);

      expect(failed.error, 'Choose from 1 to 5 stars');
      expect(ratings.createCalls, 0);
    });
  });

  group('create, update and delete', () {
    test(
      'submitting saves the rating of this request for this driver',
      () async {
        bloc = build(_clientId);
        await start();
        await pick(5);
        bloc.add(const CommentChanged('  Careful with the sofa  '));
        await bloc.stream.firstWhere((s) => s.comment.isNotEmpty);

        expect(bloc.state.canSubmit, isTrue);
        bloc.add(const RatingSubmitted());
        final done = await bloc.stream.firstWhere((s) => s.outcome != null);

        expect(done.outcome, RatingOutcome.created);
        final saved = ratings.saved!;
        expect(saved.requestId, 'r1');
        expect(saved.clientId, _clientId);
        expect(saved.driverId, _driverId);
        expect(saved.stars, 5);
        expect(saved.comment, 'Careful with the sofa'); // trimmed
        expect(done.existing, saved);
        expect(done.saving, isFalse);
      },
    );

    test(
      'rating again changes the saved rating instead of adding one',
      () async {
        bloc = build(_clientId);
        await start();
        await pick(5);
        bloc.add(const RatingSubmitted());
        await bloc.stream.firstWhere((s) => s.outcome == RatingOutcome.created);

        await pick(2);
        expect(bloc.state.canSubmit, isTrue);
        bloc.add(const RatingSubmitted());
        final done = await bloc.stream.firstWhere(
          (s) => s.outcome == RatingOutcome.updated,
        );

        expect(done.existing!.stars, 2);
        expect(ratings.saved!.stars, 2);
        expect(ratings.createCalls, 1);
        expect(ratings.updateCalls, 1);
      },
    );

    test('after saving there is nothing new to submit', () async {
      bloc = build(_clientId);
      await start();
      await pick(3);
      bloc.add(const RatingSubmitted());
      await bloc.stream.firstWhere((s) => s.outcome != null);

      expect(bloc.state.canSubmit, isFalse);
    });

    test('deleting clears the rating so the client can rate again', () async {
      bloc = build(_clientId);
      await start();
      await pick(4);
      bloc.add(const RatingSubmitted());
      await bloc.stream.firstWhere((s) => s.outcome == RatingOutcome.created);

      bloc.add(const RatingDeleted());
      final done = await bloc.stream.firstWhere(
        (s) => s.outcome == RatingOutcome.deleted,
      );

      expect(done.existing, isNull);
      expect(done.stars, 0);
      expect(done.comment, '');
      expect(ratings.saved, isNull);

      await pick(5);
      expect(bloc.state.canSubmit, isTrue);
    });

    test('deleting when there is no rating does nothing', () async {
      bloc = build(_clientId);
      await start();

      bloc.add(const RatingDeleted());
      await Future<void>.delayed(Duration.zero);

      expect(ratings.deleteCalls, 0);
    });

    test('tapping submit twice saves once', () async {
      bloc = build(_clientId);
      await start();
      await pick(5);

      bloc
        ..add(const RatingSubmitted())
        ..add(const RatingSubmitted());
      await bloc.stream.firstWhere((s) => s.outcome != null);
      await Future<void>.delayed(Duration.zero);

      expect(ratings.createCalls, 1);
      expect(ratings.updateCalls, 0);
    });

    test('a failed save shows a readable error and keeps the stars', () async {
      bloc = build(_clientId);
      await start();
      await pick(5);
      ratings.failWith = 'You are not allowed to rate this request';

      bloc.add(const RatingSubmitted());
      final failed = await bloc.stream.firstWhere((s) => s.error != null);

      expect(failed.error, 'You are not allowed to rate this request');
      expect(failed.saving, isFalse);
      expect(failed.stars, 5);
      expect(failed.existing, isNull);
    });

    test('a failed delete keeps the rating', () async {
      bloc = build(_clientId);
      await start();
      await pick(5);
      bloc.add(const RatingSubmitted());
      await bloc.stream.firstWhere((s) => s.outcome != null);
      ratings.failWith = 'No internet connection';

      bloc.add(const RatingDeleted());
      final failed = await bloc.stream.firstWhere((s) => s.error != null);

      expect(failed.error, 'No internet connection');
      expect(failed.existing, isNotNull);
      expect(failed.stars, 5);
    });
  });
}
