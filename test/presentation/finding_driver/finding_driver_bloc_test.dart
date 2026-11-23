import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/domain/entities/move_request.dart';
import 'package:imuka_kigali/presentation/screens/finding_driver/finding_driver_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/request_test_helpers.dart';

void main() {
  late MockRequestRepository repo;

  final open = buildRequest();
  final accepted = buildRequest(status: RequestStatus.accepted, driverId: 'd1');
  final cancelled = buildRequest(status: RequestStatus.cancelled);

  setUp(() => repo = MockRequestRepository());

  FindingDriverBloc build() => FindingDriverBloc(repo, 'r1');

  group('watching the request', () {
    blocTest<FindingDriverBloc, FindingDriverState>(
      'is searching while the request is open',
      setUp: () =>
          when(() => repo.watchRequest('r1'))
              .thenAnswer((_) => Stream.value(open)),
      build: build,
      act: (bloc) => bloc.add(const FindingDriverStarted()),
      expect: () => [
        FindingDriverState(
          status: FindingDriverStatus.searching,
          request: open,
        ),
      ],
    );

    blocTest<FindingDriverBloc, FindingDriverState>(
      'moves to accepted when a driver takes the job',
      setUp: () =>
          when(() => repo.watchRequest('r1'))
              .thenAnswer((_) => Stream.fromIterable([open, accepted])),
      build: build,
      act: (bloc) => bloc.add(const FindingDriverStarted()),
      expect: () => [
        FindingDriverState(
          status: FindingDriverStatus.searching,
          request: open,
        ),
        FindingDriverState(
          status: FindingDriverStatus.accepted,
          request: accepted,
        ),
      ],
    );

    blocTest<FindingDriverBloc, FindingDriverState>(
      'moves to cancelled when the request is cancelled',
      setUp: () =>
          when(() => repo.watchRequest('r1'))
              .thenAnswer((_) => Stream.fromIterable([open, cancelled])),
      build: build,
      act: (bloc) => bloc.add(const FindingDriverStarted()),
      expect: () => [
        FindingDriverState(
          status: FindingDriverStatus.searching,
          request: open,
        ),
        FindingDriverState(
          status: FindingDriverStatus.cancelled,
          request: cancelled,
        ),
      ],
    );

    blocTest<FindingDriverBloc, FindingDriverState>(
      'fails when the request does not exist',
      setUp: () =>
          when(() => repo.watchRequest('r1'))
              .thenAnswer((_) => Stream<MoveRequest?>.value(null)),
      build: build,
      act: (bloc) => bloc.add(const FindingDriverStarted()),
      expect: () => [
        const FindingDriverState(
          status: FindingDriverStatus.failure,
          error: 'Request not found',
        ),
      ],
    );

    blocTest<FindingDriverBloc, FindingDriverState>(
      'fails when the stream errors',
      setUp: () =>
          when(() => repo.watchRequest('r1'))
              .thenAnswer((_) => Stream.error(Exception('boom'))),
      build: build,
      act: (bloc) => bloc.add(const FindingDriverStarted()),
      expect: () => [
        const FindingDriverState(
          status: FindingDriverStatus.failure,
          error: 'boom',
        ),
      ],
    );
  });

  group('status edge cases', () {
    test('starts in loading', () {
      final bloc = build();
      expect(bloc.state, const FindingDriverState());
      expect(bloc.state.status, FindingDriverStatus.loading);
      bloc.close();
    });

    final completed = buildRequest(
      status: RequestStatus.completed,
      driverId: 'd1',
    );

    blocTest<FindingDriverBloc, FindingDriverState>(
      'treats a completed request as having a driver',
      setUp: () =>
          when(() => repo.watchRequest('r1'))
              .thenAnswer((_) => Stream.value(completed)),
      build: build,
      act: (bloc) => bloc.add(const FindingDriverStarted()),
      expect: () => [
        FindingDriverState(
          status: FindingDriverStatus.accepted,
          request: completed,
        ),
      ],
      verify: (_) => verify(() => repo.watchRequest('r1')).called(1),
    );

    test('can retry after the stream fails', () async {
      var calls = 0;
      when(() => repo.watchRequest('r1')).thenAnswer((_) {
        calls++;
        return calls == 1
            ? Stream<MoveRequest?>.error(Exception('boom'))
            : Stream.value(open);
      });
      final bloc = build()..add(const FindingDriverStarted());
      await pumpEventQueue();
      expect(bloc.state.status, FindingDriverStatus.failure);

      bloc.add(const FindingDriverStarted());
      await pumpEventQueue();

      expect(
        bloc.state,
        FindingDriverState(
          status: FindingDriverStatus.searching,
          request: open,
        ),
      );
      await bloc.close();
    });

    test('a live update during cancel ends on cancelled', () async {
      final updates = StreamController<MoveRequest?>();
      final gate = Completer<void>();
      when(() => repo.watchRequest('r1')).thenAnswer((_) => updates.stream);
      when(() => repo.cancelRequest('r1')).thenAnswer((_) => gate.future);
      final bloc = build()..add(const FindingDriverStarted());
      updates.add(open);
      await pumpEventQueue();

      bloc.add(const CancelRequested());
      await pumpEventQueue();
      expect(bloc.state.cancelling, isTrue);

      updates.add(cancelled);
      await pumpEventQueue();
      gate.complete();
      await pumpEventQueue();

      expect(
        bloc.state,
        FindingDriverState(
          status: FindingDriverStatus.cancelled,
          request: cancelled,
        ),
      );
      await bloc.close();
      await updates.close();
    });
  });

  group('cancelling', () {
    final searching = FindingDriverState(
      status: FindingDriverStatus.searching,
      request: open,
    );

    blocTest<FindingDriverBloc, FindingDriverState>(
      'cancels the request through the repository',
      setUp: () =>
          when(() => repo.cancelRequest('r1')).thenAnswer((_) async {}),
      build: build,
      seed: () => searching,
      act: (bloc) => bloc.add(const CancelRequested()),
      expect: () => [
        searching.copyWith(cancelling: true),
        searching.copyWith(cancelling: false),
      ],
      verify: (_) => verify(() => repo.cancelRequest('r1')).called(1),
    );

    blocTest<FindingDriverBloc, FindingDriverState>(
      'shows the error when cancelling is no longer allowed',
      setUp: () => when(() => repo.cancelRequest('r1')).thenAnswer(
        (_) =>
            Future.error(Exception('This request can no longer be cancelled')),
      ),
      build: build,
      seed: () => searching,
      act: (bloc) => bloc.add(const CancelRequested()),
      expect: () => [
        searching.copyWith(cancelling: true),
        searching.copyWith(
          cancelling: false,
          error: 'This request can no longer be cancelled',
        ),
      ],
    );
  });
}
