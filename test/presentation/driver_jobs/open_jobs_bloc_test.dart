import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/core/constants/pricing.dart';
import 'package:imuka_kigali/presentation/screens/driver_jobs/open_jobs_bloc.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  late FakeDriverJobRepository jobRepo;
  late FakeVehicleRepository vehicleRepo;
  late OpenJobsBloc bloc;

  final truck = testVehicle(vehicleType: VehicleTypes.truck);
  final jobA = testJob(id: 'a', status: RequestStatus.open);
  final jobB = testJob(id: 'b', status: RequestStatus.open);

  setUp(() {
    jobRepo = FakeDriverJobRepository();
    vehicleRepo = FakeVehicleRepository()..vehicle = testVehicle();
    bloc = OpenJobsBloc(jobRepo, vehicleRepo);
  });

  tearDown(() => bloc.close());

  test('starts in the initial state', () {
    expect(bloc.state, const OpenJobsState());
  });

  test('watches open jobs for the type of my own vehicle', () async {
    vehicleRepo.vehicle = truck;
    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        const OpenJobsState(status: OpenJobsStatus.loading),
        OpenJobsState(
          status: OpenJobsStatus.success,
          vehicle: truck,
          jobs: [jobA, jobB],
        ),
      ]),
    );

    bloc.add(const OpenJobsStarted(driverId));
    await bloc.stream.firstWhere((s) => s.status == OpenJobsStatus.loading);
    await pumpEventQueue();
    jobRepo.openJobs.add([jobA, jobB]);

    await states;
    expect(vehicleRepo.requestedDriverId, driverId);
    expect(jobRepo.watchedVehicleType, VehicleTypes.truck);
  });

  test('a driver without a vehicle sees no jobs', () async {
    vehicleRepo.vehicle = null;

    bloc.add(const OpenJobsStarted(driverId));
    final state = await bloc.stream.firstWhere(
      (s) => s.status != OpenJobsStatus.loading,
    );

    expect(state.status, OpenJobsStatus.noVehicle);
    expect(jobRepo.watchedVehicleType, isNull);
  });

  test('shows the error when the vehicle cannot be loaded', () async {
    vehicleRepo.getVehicleError = 'No internet connection. Please try again.';

    bloc.add(const OpenJobsStarted(driverId));
    final state = await bloc.stream.firstWhere(
      (s) => s.status == OpenJobsStatus.failure,
    );

    expect(state.error, 'No internet connection. Please try again.');
  });

  test('asks me to sign in again when there is no driver id', () async {
    bloc.add(const OpenJobsStarted(''));
    final state = await bloc.stream.first;

    expect(state.status, OpenJobsStatus.failure);
    expect(state.error, 'Please sign in again to see open jobs');
    expect(vehicleRepo.requestedDriverId, isNull);
  });

  test(
    'a job taken by someone else leaves the list without a refresh',
    () async {
      bloc.add(const OpenJobsStarted(driverId));
      await pumpEventQueue();
      jobRepo.openJobs.add([jobA, jobB]);
      await bloc.stream.firstWhere((s) => s.jobs.length == 2);

      jobRepo.openJobs.add([jobB]);
      final state = await bloc.stream.firstWhere((s) => s.jobs.length == 1);

      expect(state.jobs, [jobB]);
    },
  );

  test('a new request appears without a refresh', () async {
    bloc.add(const OpenJobsStarted(driverId));
    await pumpEventQueue();
    jobRepo.openJobs.add([jobA]);
    await bloc.stream.firstWhere((s) => s.status == OpenJobsStatus.success);

    jobRepo.openJobs.add([jobB, jobA]);
    final state = await bloc.stream.firstWhere((s) => s.jobs.length == 2);

    expect(state.jobs.first, jobB);
  });

  test('shows the error without the "Exception: " prefix', () async {
    bloc.add(const OpenJobsStarted(driverId));
    await pumpEventQueue();
    jobRepo.openJobs.addError(Exception('The query requires an index'));

    final state = await bloc.stream.firstWhere(
      (s) => s.status == OpenJobsStatus.failure,
    );
    expect(state.error, 'The query requires an index');
  });
}
