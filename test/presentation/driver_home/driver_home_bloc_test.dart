import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/core/constants/pricing.dart';
import 'package:imuka_kigali/presentation/screens/driver_home/driver_home_bloc.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/fake_vehicle_repository.dart';

void main() {
  late FakeDriverJobRepository jobRepo;
  late FakeVehicleRepository vehicleRepo;
  late DriverHomeBloc bloc;

  final vehicle = testVehicle();

  setUp(() {
    jobRepo = FakeDriverJobRepository();
    vehicleRepo = FakeVehicleRepository()..stored = vehicle;
    bloc = DriverHomeBloc(jobRepo, vehicleRepo);
  });

  tearDown(() => bloc.close());

  Future<void> startWithVehicle() async {
    bloc.add(const DriverHomeStarted(driverId));
    await bloc.stream.firstWhere((s) => s.status == DriverHomeStatus.success);
  }

  test('starts in the initial state', () {
    expect(bloc.state, const DriverHomeState());
  });

  test('a driver without a vehicle gets the no-vehicle state', () async {
    vehicleRepo.stored = null;
    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        const DriverHomeState(status: DriverHomeStatus.loading),
        const DriverHomeState(status: DriverHomeStatus.noVehicle),
      ]),
    );

    bloc.add(const DriverHomeStarted(driverId));

    await states;
    expect(vehicleRepo.requestedDriverIds, [driverId]);
    expect(jobRepo.watchedVehicleType, isNull);
  });

  test('loads my vehicle, then counts open jobs for its type', () async {
    vehicleRepo.stored = testVehicle(vehicleType: VehicleTypes.van);

    await startWithVehicle();
    jobRepo.openJobs.add([
      testJob(id: 'a', status: RequestStatus.open),
      testJob(id: 'b', status: RequestStatus.open),
    ]);
    final state = await bloc.stream.firstWhere((s) => s.openJobCount == 2);

    expect(state.vehicle?.vehicleType, VehicleTypes.van);
    expect(jobRepo.watchedVehicleType, VehicleTypes.van);
  });

  test('works out earnings and accepted moves from my jobs', () async {
    await startWithVehicle();
    jobRepo.myJobs.add([
      testJob(id: 'acc', status: RequestStatus.accepted, amount: 12000),
      testJob(id: 'done1', amount: 24000),
      testJob(id: 'done2', amount: 15000),
      testJob(id: 'gone', status: RequestStatus.cancelled, amount: 30000),
    ]);
    final state = await bloc.stream.firstWhere((s) => s.myJobs.isNotEmpty);

    expect(jobRepo.watchedDriverId, driverId);
    expect(state.totalEarnings, 39000);
    expect(state.completedCount, 2);
    expect(state.acceptedJobs.map((job) => job.id), ['acc']);
  });

  test('both lists stay live', () async {
    await startWithVehicle();
    jobRepo.openJobs.add([testJob(id: 'a', status: RequestStatus.open)]);
    jobRepo.myJobs.add([testJob(id: 'done')]);
    await bloc.stream.firstWhere(
      (s) => s.openJobCount == 1 && s.completedCount == 1,
    );

    jobRepo.openJobs.add([]);
    final state = await bloc.stream.firstWhere((s) => s.openJobCount == 0);

    expect(state.completedCount, 1);
  });

  test('shows the error when the vehicle cannot be loaded', () async {
    vehicleRepo.getError = 'No internet connection. Please try again.';

    bloc.add(const DriverHomeStarted(driverId));
    final state = await bloc.stream.firstWhere(
      (s) => s.status == DriverHomeStatus.failure,
    );

    expect(state.error, 'No internet connection. Please try again.');
  });

  test('keeps a stream error when the other list updates', () async {
    await startWithVehicle();
    jobRepo.openJobs.addError(Exception('The query requires an index'));
    await bloc.stream.firstWhere((s) => s.status == DriverHomeStatus.failure);

    jobRepo.myJobs.add([testJob(id: 'done')]);
    final state = await bloc.stream.firstWhere((s) => s.myJobs.isNotEmpty);

    expect(state.status, DriverHomeStatus.failure);
    expect(state.error, 'The query requires an index');
  });

  test('asks me to sign in again when there is no driver id', () async {
    bloc.add(const DriverHomeStarted(''));
    final state = await bloc.stream.first;

    expect(state.status, DriverHomeStatus.failure);
    expect(state.error, 'Please sign in again to see your jobs');
    expect(vehicleRepo.requestedDriverIds, isEmpty);
  });
}
