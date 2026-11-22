import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/domain/entities/vehicle.dart';
import 'package:imuka_kigali/presentation/screens/driver_contact/driver_contact_bloc.dart';

import '../helpers/fake_repositories.dart';
import '../helpers/fake_request_repository.dart';
import '../helpers/fake_vehicle_repository.dart';

/// The vehicle the fake returns for driver1.
const _vehicle = Vehicle(
  id: 'vehicle1',
  driverId: 'driver1',
  vehicleType: 'pickup',
  plateNumber: 'RAD 428 E',
  capacityKg: 1000,
);

void main() {
  late FakeRequestRepository requests;
  late FakeAuthRepository users;
  late FakeVehicleRepository vehicles;
  late DriverContactBloc bloc;

  /// Starts the bloc and waits until the request has arrived.
  Future<void> start() async {
    bloc.add(const DriverContactStarted());
    await bloc.stream.firstWhere(
      (s) => s.status != DriverContactStatus.loading,
    );
  }

  /// Waits until the driver's details have finished loading.
  Future<DriverContactState> detailsDone() => bloc.stream.firstWhere(
    (s) => s.detailsStatus != DriverDetailsStatus.loading,
  );

  setUp(() {
    requests = FakeRequestRepository(dealRequest());
    users = FakeAuthRepository()
      ..users['driver1'] = testUser(
        'driver1',
        'Jean Driver',
        role: UserRoles.driver,
      );
    vehicles = FakeVehicleRepository()..stored = _vehicle;
    bloc = DriverContactBloc(requests, users, vehicles, 'r1');
  });

  tearDown(() => bloc.close());

  group('the request', () {
    test('starts loading', () {
      expect(bloc.state.status, DriverContactStatus.loading);
    });

    test('shows the request, with its fixed price', () async {
      await start();

      expect(bloc.state.status, DriverContactStatus.ready);
      expect(bloc.state.request!.proposedAmount, 12500);
      expect(bloc.state.hasDriver, isTrue);
    });

    test('a missing request is a failure', () async {
      requests = FakeRequestRepository(null);
      bloc = DriverContactBloc(requests, users, vehicles, 'r1');
      await start();

      expect(bloc.state.status, DriverContactStatus.failure);
      expect(bloc.state.error, 'Request not found');
    });

    test('a request nobody accepted yet has no driver to load', () async {
      requests = FakeRequestRepository(
        dealRequest(driverId: '', status: RequestStatus.open),
      );
      bloc = DriverContactBloc(requests, users, vehicles, 'r1');
      await start();
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.hasDriver, isFalse);
      expect(users.getUserCalls, isEmpty);
      expect(vehicles.requestedDriverIds, isEmpty);
    });

    test('a cancelled request does not count as having a driver', () async {
      requests = FakeRequestRepository(
        dealRequest(status: RequestStatus.cancelled),
      );
      bloc = DriverContactBloc(requests, users, vehicles, 'r1');
      await start();

      expect(bloc.state.hasDriver, isFalse);
    });

    test('a driver who accepts later shows up live', () async {
      requests = FakeRequestRepository(
        dealRequest(driverId: '', status: RequestStatus.open),
      );
      bloc = DriverContactBloc(requests, users, vehicles, 'r1');
      await start();
      expect(bloc.state.hasDriver, isFalse);

      requests.emit(dealRequest());
      final done = await detailsDone();

      expect(done.driver!.fullName, 'Jean Driver');
    });
  });

  group('the driver and the vehicle', () {
    test('loads the driver name and phone and the vehicle', () async {
      await start();
      final done = await detailsDone();

      expect(done.detailsStatus, DriverDetailsStatus.loaded);
      expect(done.driver!.fullName, 'Jean Driver');
      expect(done.driver!.phone, '0788000000');
      expect(done.vehicle!.plateNumber, 'RAD 428 E');
      expect(users.getUserCalls, ['driver1']);
      expect(vehicles.requestedDriverIds, ['driver1']);
    });

    test('a driver without a vehicle still loads', () async {
      vehicles.stored = null;
      await start();
      final done = await detailsDone();

      expect(done.detailsStatus, DriverDetailsStatus.loaded);
      expect(done.driver, isNotNull);
      expect(done.vehicle, isNull);
    });

    test('if the profile fails, the vehicle and price still show', () async {
      users.failingUserIds.add('driver1');
      await start();
      final done = await detailsDone();

      expect(done.detailsStatus, DriverDetailsStatus.failure);
      expect(done.error, 'No permission');
      expect(done.driver, isNull);
      expect(done.vehicle, isNotNull);
      expect(done.request!.proposedAmount, 12500);
    });

    test('if the vehicle fails, the driver still shows', () async {
      vehicles.getError = 'No internet connection';
      await start();
      final done = await detailsDone();

      expect(done.detailsStatus, DriverDetailsStatus.failure);
      expect(done.error, 'No internet connection');
      expect(done.driver!.fullName, 'Jean Driver');
    });

    test('a request update does not load the driver again', () async {
      await start();
      await detailsDone();

      requests.emit(dealRequest(clientConfirmed: true));
      await Future<void>.delayed(Duration.zero);

      expect(users.getUserCalls, hasLength(1));
      expect(vehicles.requestedDriverIds, hasLength(1));
    });

    test('trying again after a failure loads the details', () async {
      users.failingUserIds.add('driver1');
      await start();
      await detailsDone();

      users.failingUserIds.clear();
      bloc.add(const DriverDetailsRequested('driver1'));
      final done = await bloc.stream.firstWhere(
        (s) => s.detailsStatus == DriverDetailsStatus.loaded,
      );

      expect(done.driver!.fullName, 'Jean Driver');
      expect(done.error, isNull);
    });
  });
}
