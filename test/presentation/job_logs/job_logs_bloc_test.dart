import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/presentation/screens/job_logs/job_logs_bloc.dart';

import 'job_logs_fakes.dart';

void main() {
  late FakeDriverJobRepository jobRepo;
  late FakeAuthRepository authRepo;
  late JobLogsBloc bloc;

  setUp(() {
    jobRepo = FakeDriverJobRepository();
    authRepo = FakeAuthRepository()
      ..users['client1'] = testUser('client1', 'Diane Uwase')
      ..users['client2'] = testUser('client2', 'Eric Mugisha');
    bloc = JobLogsBloc(jobRepo, authRepo);
  });

  tearDown(() => bloc.close());

  Future<JobLogsState> firstStateWith(JobLogsStatus status) =>
      bloc.stream.firstWhere((state) => state.status == status);

  test('starts in the initial state', () {
    expect(bloc.state, const JobLogsState());
  });

  test('fails with a sign-in message when there is no driver id', () async {
    bloc.add(const JobLogsRequested(''));

    final state = await firstStateWith(JobLogsStatus.failure);
    expect(state.error, 'Please sign in again to see your jobs');
    expect(jobRepo.watchedDriverId, isNull);
  });

  test('shows loading, then my jobs with client names', () async {
    final jobs = [
      testJob(id: 'a', clientId: 'client1'),
      testJob(id: 'b', clientId: 'client2', status: RequestStatus.accepted),
    ];
    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<JobLogsState>().having(
          (s) => s.status,
          'status',
          JobLogsStatus.loading,
        ),
        isA<JobLogsState>()
            .having((s) => s.status, 'status', JobLogsStatus.success)
            .having((s) => s.visibleJobs, 'visibleJobs', jobs)
            .having((s) => s.clientNames, 'clientNames', {
              'client1': 'Diane Uwase',
              'client2': 'Eric Mugisha',
            }),
      ]),
    );

    bloc.add(const JobLogsRequested(driverId));
    jobRepo.myJobs.add(jobs);

    await states;
    expect(jobRepo.watchedDriverId, driverId);
  });

  test('adds up earnings only from completed jobs', () async {
    bloc.add(const JobLogsRequested(driverId));
    jobRepo.myJobs.add([
      testJob(id: 'a', amount: 24000),
      testJob(id: 'b', amount: 18000),
      testJob(id: 'c', amount: 32000, status: RequestStatus.accepted),
      testJob(id: 'd', amount: 38000, status: RequestStatus.cancelled),
    ]);

    final state = await firstStateWith(JobLogsStatus.success);
    expect(state.totalEarnings, 42000);
    expect(state.completedCount, 2);
    expect(state.inProgressCount, 1);
  });

  test('shows the error without the "Exception: " prefix', () async {
    bloc.add(const JobLogsRequested(driverId));
    jobRepo.myJobs.addError(Exception('Could not load your jobs'));

    final state = await firstStateWith(JobLogsStatus.failure);
    expect(state.error, 'Could not load your jobs');
  });

  test('a failed client lookup does not break the list', () async {
    authRepo.failingUserIds.add('client2');
    bloc.add(const JobLogsRequested(driverId));
    jobRepo.myJobs.add([
      testJob(id: 'a', clientId: 'client1'),
      testJob(id: 'b', clientId: 'client2'),
    ]);

    final state = await firstStateWith(JobLogsStatus.success);
    expect(state.visibleJobs, hasLength(2));
    expect(state.clientNames, {'client1': 'Diane Uwase'});
  });

  test('a client with no profile gets an empty name', () async {
    bloc.add(const JobLogsRequested(driverId));
    jobRepo.myJobs.add([testJob(id: 'a', clientId: 'unknown')]);

    final state = await firstStateWith(JobLogsStatus.success);
    expect(state.clientNames, {'unknown': ''});
  });

  test('reads each client name once across updates', () async {
    bloc.add(const JobLogsRequested(driverId));
    jobRepo.myJobs.add([testJob(id: 'a', clientId: 'client1')]);
    await firstStateWith(JobLogsStatus.success);

    jobRepo.myJobs.add([
      testJob(id: 'a', clientId: 'client1'),
      testJob(id: 'b', clientId: 'client1'),
    ]);
    await bloc.stream.firstWhere((state) => state.allJobs.length == 2);

    expect(authRepo.getUserCalls, ['client1']);
  });

  test('retries a failed client name on the next update', () async {
    authRepo.failingUserIds.add('client1');
    bloc.add(const JobLogsRequested(driverId));
    jobRepo.myJobs.add([testJob(id: 'a')]);
    await firstStateWith(JobLogsStatus.success);

    authRepo.failingUserIds.clear();
    jobRepo.myJobs.add([testJob(id: 'a'), testJob(id: 'b')]);
    final state = await bloc.stream.firstWhere(
      (state) => state.allJobs.length == 2,
    );

    expect(state.clientNames, {'client1': 'Diane Uwase'});
  });

  group('period tabs', () {
    final now = DateTime.now();
    final today = testJob(id: 'today', createdAt: now);
    final eightDaysAgo = testJob(
      id: 'eight',
      createdAt: now.subtract(const Duration(days: 8)),
    );
    final fortyDaysAgo = testJob(
      id: 'forty',
      createdAt: now.subtract(const Duration(days: 40)),
    );

    Future<void> loadJobs() async {
      bloc.add(const JobLogsRequested(driverId));
      jobRepo.myJobs.add([today, eightDaysAgo, fortyDaysAgo]);
      await firstStateWith(JobLogsStatus.success);
    }

    test('All Trips shows every job', () async {
      await loadJobs();
      expect(bloc.state.visibleJobs, [today, eightDaysAgo, fortyDaysAgo]);
    });

    test('This Week hides jobs from before this week', () async {
      await loadJobs();
      bloc.add(const JobLogsPeriodChanged(JobLogsPeriod.thisWeek));

      final state = await bloc.stream.first;
      expect(state.period, JobLogsPeriod.thisWeek);
      expect(state.visibleJobs, [today]);
      expect(state.allJobs, hasLength(3));
    });

    test('This Month hides jobs from before this month', () async {
      await loadJobs();
      bloc.add(const JobLogsPeriodChanged(JobLogsPeriod.thisMonth));

      final state = await bloc.stream.first;
      expect(state.visibleJobs, contains(today));
      expect(state.visibleJobs, isNot(contains(fortyDaysAgo)));
    });

    test('the summary follows the selected period', () async {
      await loadJobs();
      bloc.add(const JobLogsPeriodChanged(JobLogsPeriod.thisWeek));

      final state = await bloc.stream.first;
      expect(state.completedCount, 1);
      expect(state.totalEarnings, today.proposedAmount);
    });

    test('a new update keeps the selected period', () async {
      await loadJobs();
      bloc.add(const JobLogsPeriodChanged(JobLogsPeriod.thisWeek));
      await bloc.stream.first;

      jobRepo.myJobs.add([today, eightDaysAgo]);
      final state = await bloc.stream.firstWhere(
        (state) => state.allJobs.length == 2,
      );
      expect(state.visibleJobs, [today]);
    });
  });
}
