import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/core/constants/pricing.dart';
import 'package:imuka_kigali/presentation/screens/driver_jobs/open_jobs_bloc.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  late FakeDriverJobRepository jobRepo;
  late OpenJobsBloc bloc;

  setUp(() {
    jobRepo = FakeDriverJobRepository();
    bloc = OpenJobsBloc(jobRepo);
  });

  tearDown(() => bloc.close());

  final jobA = testJob(id: 'a', status: RequestStatus.open);
  final jobB = testJob(id: 'b', status: RequestStatus.open);

  test('starts in the initial state', () {
    expect(bloc.state, const OpenJobsState());
  });

  test('watches open jobs for the vehicle type it is given', () async {
    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        const OpenJobsState(status: OpenJobsStatus.loading),
        OpenJobsState(status: OpenJobsStatus.success, jobs: [jobA, jobB]),
      ]),
    );

    bloc.add(const OpenJobsStarted(VehicleTypes.truck));
    jobRepo.openJobs.add([jobA, jobB]);

    await states;
    expect(jobRepo.watchedVehicleType, VehicleTypes.truck);
  });

  test(
    'a job taken by someone else leaves the list without a refresh',
    () async {
      bloc.add(const OpenJobsStarted(VehicleTypes.pickup));
      jobRepo.openJobs.add([jobA, jobB]);
      await bloc.stream.firstWhere((s) => s.jobs.length == 2);

      jobRepo.openJobs.add([jobB]);
      final state = await bloc.stream.firstWhere((s) => s.jobs.length == 1);

      expect(state.jobs, [jobB]);
    },
  );

  test('a new request appears without a refresh', () async {
    bloc.add(const OpenJobsStarted(VehicleTypes.pickup));
    jobRepo.openJobs.add([jobA]);
    await bloc.stream.firstWhere((s) => s.status == OpenJobsStatus.success);

    jobRepo.openJobs.add([jobB, jobA]);
    final state = await bloc.stream.firstWhere((s) => s.jobs.length == 2);

    expect(state.jobs.first, jobB);
  });

  test('shows the error without the "Exception: " prefix', () async {
    bloc.add(const OpenJobsStarted(VehicleTypes.pickup));
    jobRepo.openJobs.addError(Exception('The query requires an index'));

    final state = await bloc.stream.firstWhere(
      (s) => s.status == OpenJobsStatus.failure,
    );
    expect(state.error, 'The query requires an index');
  });
}
