import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/pricing.dart';
import 'package:imuka_kigali/domain/entities/vehicle.dart';
import 'package:imuka_kigali/domain/entities/vehicle_class.dart';
import 'package:imuka_kigali/presentation/screens/driver_profile/driver_profile_bloc.dart';

import '../helpers/fake_vehicle_repository.dart';

/// The vehicle most tests start with.
const pickup = Vehicle(
  id: 'v1',
  driverId: FakeVehicleRepository.ownerId,
  vehicleType: VehicleTypes.pickup,
  plateNumber: 'RAD 428 E',
  capacityKg: 1500,
);

/// Unit tests for the bloc behind the driver profile. Run them with:
/// flutter test test/presentation/driver_profile_bloc_test.dart
void main() {
  late FakeVehicleRepository vehicles;
  late DriverProfileBloc bloc;

  setUp(() {
    vehicles = FakeVehicleRepository();
    bloc = DriverProfileBloc(vehicles);
  });

  tearDown(() => bloc.close());

  /// Opens the profile of a driver whose vehicle is [vehicle] (null means
  /// no vehicle) and waits until it has loaded.
  Future<void> openProfile(Vehicle? vehicle) async {
    vehicles.stored = vehicle;
    bloc.add(const DriverProfileRequested(FakeVehicleRepository.ownerId));
    await settle();
  }

  group('loading', () {
    test('starts with nothing loaded', () {
      expect(bloc.state, const DriverProfileState());
      expect(bloc.state.hasLoaded, isFalse);
    });

    test('loads the vehicle of the driver it is given', () async {
      vehicles.stored = pickup;
      final states = expectLater(
        bloc.stream,
        emitsInOrder([
          const DriverProfileState(status: DriverProfileStatus.loading),
          const DriverProfileState(
            status: DriverProfileStatus.success,
            hasLoaded: true,
            vehicle: pickup,
          ),
        ]),
      );

      bloc.add(const DriverProfileRequested(FakeVehicleRepository.ownerId));

      await states;
      expect(vehicles.requestedDriverIds, [FakeVehicleRepository.ownerId]);
    });

    test('a driver with no vehicle loads with an empty vehicle', () async {
      await openProfile(null);

      expect(bloc.state.status, DriverProfileStatus.success);
      expect(bloc.state.hasLoaded, isTrue);
      expect(bloc.state.vehicle, isNull);
    });

    test('a failed load shows the error without "Exception: "', () async {
      vehicles.getError = 'Permission denied.';
      await openProfile(pickup);

      expect(bloc.state.status, DriverProfileStatus.failure);
      expect(bloc.state.error, 'Permission denied.');
      expect(bloc.state.hasLoaded, isFalse);
    });
  });

  group('vehicle class', () {
    test('a new class is saved with the capacity of that class', () async {
      await openProfile(pickup);

      bloc.add(const DriverVehicleTypeChanged(VehicleTypes.van));
      await settle();

      final saved = vehicles.updatedVehicles.single;
      expect(saved.id, pickup.id);
      expect(saved.vehicleType, VehicleTypes.van);
      expect(saved.capacityKg, VehicleClasses.of(VehicleTypes.van).capacityKg);
      expect(saved.plateNumber, pickup.plateNumber);
      expect(bloc.state.vehicle, saved);
      expect(bloc.state.message, 'Vehicle class updated.');
    });

    test('picking the class the vehicle already has saves nothing', () async {
      await openProfile(pickup);

      bloc.add(const DriverVehicleTypeChanged(VehicleTypes.pickup));
      await settle();

      expect(vehicles.updatedVehicles, isEmpty);
      expect(bloc.state.vehicle, pickup);
    });

    test('switching a car plate to a tricycle is refused', () async {
      await openProfile(pickup);

      bloc.add(const DriverVehicleTypeChanged(VehicleTypes.tricycle));
      await settle();

      expect(bloc.state.status, DriverProfileStatus.failure);
      expect(bloc.state.error, contains('RD 204 E'));
      expect(bloc.state.vehicle, pickup);
      expect(vehicles.updatedVehicles, isEmpty);
    });
  });

  group('plate number', () {
    test('a new plate is saved the standard way', () async {
      await openProfile(pickup);

      bloc.add(const DriverPlateNumberChanged('rab123c'));
      await settle();

      expect(vehicles.updatedVehicles.single.plateNumber, 'RAB 123 C');
      expect(bloc.state.vehicle?.plateNumber, 'RAB 123 C');
      expect(bloc.state.message, 'Plate number updated.');
    });

    test('a wrong plate shows an error and saves nothing', () async {
      await openProfile(pickup);

      bloc.add(const DriverPlateNumberChanged('KAD 1'));
      await settle();

      expect(bloc.state.status, DriverProfileStatus.failure);
      expect(bloc.state.error, 'Enter a Rwanda plate like RAD 428 E.');
      expect(bloc.state.vehicle, pickup);
      expect(vehicles.updatedVehicles, isEmpty);
    });

    test('a tricycle only accepts a moto plate', () async {
      await openProfile(
        const Vehicle(
          id: 'v2',
          driverId: FakeVehicleRepository.ownerId,
          vehicleType: VehicleTypes.tricycle,
          plateNumber: 'RD 204 E',
          capacityKg: 350,
        ),
      );

      bloc.add(const DriverPlateNumberChanged('RAB 123 C'));
      await settle();
      expect(bloc.state.error, 'Enter a Rwanda plate like RD 204 E.');
      expect(vehicles.updatedVehicles, isEmpty);

      bloc.add(const DriverPlateNumberChanged('rf 517 b'));
      await settle();
      expect(vehicles.updatedVehicles.single.plateNumber, 'RF 517 B');
    });

    test('the same plate typed again saves nothing', () async {
      await openProfile(pickup);

      bloc.add(const DriverPlateNumberChanged('rad 428 e'));
      await settle();

      expect(vehicles.updatedVehicles, isEmpty);
    });

    test('a failed save puts the old plate back', () async {
      await openProfile(pickup);
      vehicles.updateError = 'No internet connection.';
      final states = <DriverProfileState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(const DriverPlateNumberChanged('RAB 123 C'));
      await settle();
      await subscription.cancel();

      expect(states.first.vehicle?.plateNumber, 'RAB 123 C');
      expect(states.last.vehicle, pickup);
      expect(states.last.status, DriverProfileStatus.failure);
      expect(states.last.error, 'No internet connection.');
    });
  });

  group('adding and removing', () {
    test('a driver with no vehicle can add one', () async {
      await openProfile(null);

      bloc.add(
        const DriverVehicleAdded(
          vehicleType: VehicleTypes.tricycle,
          plateNumber: 'rc123a',
        ),
      );
      await settle();

      final call = vehicles.addCalls.single;
      expect(call.vehicleType, VehicleTypes.tricycle);
      expect(call.plateNumber, 'RC 123 A');
      expect(bloc.state.vehicle?.plateNumber, 'RC 123 A');
      expect(bloc.state.isSaving, isFalse);
      expect(bloc.state.message, 'Vehicle added.');
    });

    test('isSaving is true while the new vehicle is being saved', () async {
      await openProfile(null);
      vehicles.addGate = Completer<void>();

      bloc.add(
        const DriverVehicleAdded(
          vehicleType: VehicleTypes.van,
          plateNumber: 'RAB 123 C',
        ),
      );
      await settle();
      expect(bloc.state.isSaving, isTrue);

      vehicles.addGate!.complete();
      await settle();
      expect(bloc.state.isSaving, isFalse);
    });

    test('a failed add shows the error and leaves no vehicle', () async {
      await openProfile(null);
      vehicles.addError = 'No internet connection.';

      bloc.add(
        const DriverVehicleAdded(
          vehicleType: VehicleTypes.van,
          plateNumber: 'RAB 123 C',
        ),
      );
      await settle();

      expect(bloc.state.status, DriverProfileStatus.failure);
      expect(bloc.state.error, 'No internet connection.');
      expect(bloc.state.isSaving, isFalse);
      expect(bloc.state.vehicle, isNull);
    });

    test('a driver who already has a vehicle cannot add a second', () async {
      await openProfile(pickup);

      bloc.add(
        const DriverVehicleAdded(
          vehicleType: VehicleTypes.van,
          plateNumber: 'RAB 123 C',
        ),
      );
      await settle();

      expect(vehicles.addCalls, isEmpty);
      expect(bloc.state.vehicle, pickup);
    });

    test('removing deletes the vehicle by its id', () async {
      await openProfile(pickup);

      bloc.add(const DriverVehicleDeleted());
      await settle();

      expect(vehicles.deletedIds, [pickup.id]);
      expect(bloc.state.vehicle, isNull);
      expect(bloc.state.message, 'Vehicle removed.');
    });

    test('a failed delete brings the vehicle back', () async {
      await openProfile(pickup);
      vehicles.deleteError = 'No internet connection.';

      bloc.add(const DriverVehicleDeleted());
      await settle();

      expect(bloc.state.vehicle, pickup);
      expect(bloc.state.status, DriverProfileStatus.failure);
      expect(bloc.state.error, 'No internet connection.');
    });
  });
}
