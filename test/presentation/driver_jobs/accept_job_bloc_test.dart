import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/presentation/screens/driver_jobs/accept_job_bloc.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  late FakeDriverJobRepository jobRepo;
  late FakeAuthRepository authRepo;
  late AcceptJobBloc bloc;

  final client = testUser('client1', 'Diane Uwase');
  final job = testJob(id: 'a', clientId: 'client1', status: RequestStatus.open);
  final otherJob = testJob(id: 'b', status: RequestStatus.open);

  setUp(() {
    jobRepo = FakeDriverJobRepository();
    authRepo = FakeAuthRepository()..users['client1'] = client;
    bloc = AcceptJobBloc(jobRepo, authRepo);
  });

  tearDown(() => bloc.close());

  test('starts in the initial state', () {
    expect(bloc.state, const AcceptJobState());
  });

  test('shows loading on that job, then the job and the client', () async {
    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        const AcceptJobState(
          status: AcceptJobStatus.loading,
          acceptingJobId: 'a',
        ),
        AcceptJobState(
          status: AcceptJobStatus.success,
          acceptedJob: job,
          client: client,
        ),
      ]),
    );

    bloc.add(JobAccepted(job));

    await states;
    expect(jobRepo.acceptedIds, ['a']);
  });

  test('tells the driver when another driver was faster', () async {
    jobRepo.acceptError = 'This job was just taken by another driver';
    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        const AcceptJobState(
          status: AcceptJobStatus.loading,
          acceptingJobId: 'a',
        ),
        const AcceptJobState(
          status: AcceptJobStatus.failure,
          error: 'This job was just taken by another driver',
        ),
      ]),
    );

    bloc.add(JobAccepted(job));

    await states;
  });

  test('keeps the job when the client lookup fails', () async {
    authRepo.failingUserIds.add('client1');

    bloc.add(JobAccepted(job));
    final state = await bloc.stream.firstWhere(
      (s) => s.status == AcceptJobStatus.success,
    );

    expect(state.acceptedJob, job);
    expect(state.client, isNull);
  });

  test('ignores a second accept while one is running', () async {
    jobRepo.acceptGate = Completer<void>();

    bloc.add(JobAccepted(job));
    await bloc.stream.firstWhere((s) => s.isAccepting);
    bloc.add(JobAccepted(otherJob));
    jobRepo.acceptGate!.complete();
    final state = await bloc.stream.firstWhere(
      (s) => s.status == AcceptJobStatus.success,
    );

    expect(jobRepo.acceptedIds, ['a']);
    expect(state.acceptedJob, job);
  });

  test('can try another job after one was taken', () async {
    jobRepo.acceptError = 'This job was just taken by another driver';
    bloc.add(JobAccepted(job));
    await bloc.stream.firstWhere((s) => s.status == AcceptJobStatus.failure);

    jobRepo.acceptError = null;
    bloc.add(JobAccepted(otherJob));
    final state = await bloc.stream.firstWhere(
      (s) => s.status == AcceptJobStatus.success,
    );

    expect(state.acceptedJob, otherJob);
  });
}
