import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/core/constants/kigali_areas.dart';
import 'package:imuka_kigali/core/constants/pricing.dart';
import 'package:imuka_kigali/core/utils/fare_calculator.dart';
import 'package:imuka_kigali/domain/entities/move_request.dart';
import 'package:imuka_kigali/presentation/screens/where_from_to/create_request_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/request_test_helpers.dart';

void main() {
  late MockRequestRepository repo;

  final cityCentre = KigaliAreas.all.firstWhere((a) => a.name == 'City Centre');
  final remera = KigaliAreas.all.firstWhere((a) => a.name == 'Remera');

  final filled = CreateRequestState(
    pickup: cityCentre,
    dropoff: remera,
    vehicleType: VehicleTypes.pickup,
    itemDescription: 'A sofa',
  );

  setUpAll(() => registerFallbackValue(FakeMoveRequest()));

  setUp(() => repo = MockRequestRepository());

  group('CreateRequestState', () {
    test('has no route and no price until areas and vehicle are chosen', () {
      const state = CreateRequestState();
      expect(state.hasRoute, isFalse);
      expect(state.proposedAmount, isNull);
      expect(state.canSubmit, isFalse);
    });

    test('the same pickup and drop-off is not a route', () {
      final state = CreateRequestState(
        pickup: cityCentre,
        dropoff: cityCentre,
        vehicleType: VehicleTypes.van,
      );
      expect(state.hasRoute, isFalse);
      expect(state.proposedAmount, isNull);
    });

    test('price comes from FareCalculator', () {
      final expected = FareCalculator.calculate(
        pickup: cityCentre,
        dropoff: remera,
        vehicleType: VehicleTypes.pickup,
      ).proposedAmount;
      expect(filled.proposedAmount, expected);
    });
  });

  group('canSubmit', () {
    test('is true for a complete form', () {
      expect(filled.canSubmit, isTrue);
    });

    test('is false without a vehicle', () {
      final state = CreateRequestState(
        pickup: cityCentre,
        dropoff: remera,
        itemDescription: 'A sofa',
      );
      expect(state.hasRoute, isTrue);
      expect(state.proposedAmount, isNull);
      expect(state.canSubmit, isFalse);
    });

    test('is false when the description is only spaces', () {
      expect(filled.copyWith(itemDescription: '   ').canSubmit, isFalse);
    });

    test('is false while submitting', () {
      final state = filled.copyWith(status: CreateRequestStatus.submitting);
      expect(state.canSubmit, isFalse);
    });
  });

  group('submitting edge cases', () {
    blocTest<CreateRequestBloc, CreateRequestState>(
      'saves the trimmed description, vehicle and calculated time',
      setUp: () =>
          when(() => repo.createRequest(any())).thenAnswer((_) async => 'r1'),
      build: () => CreateRequestBloc(repo),
      seed: () => filled.copyWith(itemDescription: '  A sofa  '),
      act: (bloc) => bloc.add(const RequestSubmitted('c1')),
      verify: (_) {
        final saved =
            verify(() => repo.createRequest(captureAny())).captured.single
                as MoveRequest;
        final fare = FareCalculator.calculate(
          pickup: cityCentre,
          dropoff: remera,
          vehicleType: VehicleTypes.pickup,
        );
        expect(saved.itemDescription, 'A sofa');
        expect(saved.vehicleType, VehicleTypes.pickup);
        expect(saved.estimatedMinutes, fare.estimatedMinutes);
        expect(saved.clientConfirmed, isFalse);
        expect(saved.driverConfirmed, isFalse);
      },
    );

    blocTest<CreateRequestBloc, CreateRequestState>(
      'does not save when pickup and drop-off are the same',
      build: () => CreateRequestBloc(repo),
      seed: () => filled.copyWith(dropoff: cityCentre),
      act: (bloc) => bloc.add(const RequestSubmitted('c1')),
      expect: () => <CreateRequestState>[],
      verify: (_) => verifyNever(() => repo.createRequest(any())),
    );

    blocTest<CreateRequestBloc, CreateRequestState>(
      'clears the old error when retrying after a failure',
      setUp: () =>
          when(() => repo.createRequest(any())).thenAnswer((_) async => 'r2'),
      build: () => CreateRequestBloc(repo),
      seed: () => filled.copyWith(
        status: CreateRequestStatus.failure,
        error: 'Network down',
      ),
      act: (bloc) => bloc.add(const RequestSubmitted('c1')),
      expect: () => [
        filled.copyWith(status: CreateRequestStatus.submitting),
        filled.copyWith(status: CreateRequestStatus.success, requestId: 'r2'),
      ],
    );

    test('a double tap creates only one request', () async {
      final gate = Completer<String>();
      when(() => repo.createRequest(any())).thenAnswer((_) => gate.future);
      final bloc = CreateRequestBloc(repo)
        ..add(PickupSelected(cityCentre))
        ..add(DropoffSelected(remera))
        ..add(const VehicleTypeSelected(VehicleTypes.pickup))
        ..add(const ItemDescriptionChanged('A sofa'));
      await pumpEventQueue();

      bloc
        ..add(const RequestSubmitted('c1'))
        ..add(const RequestSubmitted('c1'));
      await pumpEventQueue();
      gate.complete('r1');
      await pumpEventQueue();

      verify(() => repo.createRequest(any())).called(1);
      expect(bloc.state.status, CreateRequestStatus.success);
      await bloc.close();
    });
  });

  group('CreateRequestBloc', () {
    blocTest<CreateRequestBloc, CreateRequestState>(
      'stores the selected pickup, drop-off, vehicle and description',
      build: () => CreateRequestBloc(repo),
      act: (bloc) => bloc
        ..add(PickupSelected(cityCentre))
        ..add(DropoffSelected(remera))
        ..add(const VehicleTypeSelected(VehicleTypes.pickup))
        ..add(const ItemDescriptionChanged('A sofa')),
      expect: () => [
        CreateRequestState(pickup: cityCentre),
        CreateRequestState(pickup: cityCentre, dropoff: remera),
        CreateRequestState(
          pickup: cityCentre,
          dropoff: remera,
          vehicleType: VehicleTypes.pickup,
        ),
        filled,
      ],
    );

    blocTest<CreateRequestBloc, CreateRequestState>(
      'creates an open request without a driver and succeeds with its id',
      setUp: () =>
          when(() => repo.createRequest(any())).thenAnswer((_) async => 'r1'),
      build: () => CreateRequestBloc(repo),
      seed: () => filled,
      act: (bloc) => bloc.add(const RequestSubmitted('c1')),
      expect: () => [
        filled.copyWith(status: CreateRequestStatus.submitting),
        filled.copyWith(status: CreateRequestStatus.success, requestId: 'r1'),
      ],
      verify: (_) {
        final saved =
            verify(() => repo.createRequest(captureAny())).captured.single
                as MoveRequest;
        expect(saved.clientId, 'c1');
        expect(saved.driverId, '');
        expect(saved.status, RequestStatus.open);
        expect(saved.pickupLocation, 'City Centre');
        expect(saved.dropoffLocation, 'Remera');
        expect(saved.proposedAmount, filled.proposedAmount);
      },
    );

    blocTest<CreateRequestBloc, CreateRequestState>(
      'emits failure with a readable message when saving fails',
      setUp: () =>
          when(() => repo.createRequest(any()))
              .thenAnswer((_) => Future.error(Exception('Network down'))),
      build: () => CreateRequestBloc(repo),
      seed: () => filled,
      act: (bloc) => bloc.add(const RequestSubmitted('c1')),
      expect: () => [
        filled.copyWith(status: CreateRequestStatus.submitting),
        filled.copyWith(
          status: CreateRequestStatus.failure,
          error: 'Network down',
        ),
      ],
    );

    blocTest<CreateRequestBloc, CreateRequestState>(
      'does nothing when the form is incomplete',
      build: () => CreateRequestBloc(repo),
      act: (bloc) => bloc.add(const RequestSubmitted('c1')),
      expect: () => <CreateRequestState>[],
      verify: (_) => verifyNever(() => repo.createRequest(any())),
    );
  });
}
