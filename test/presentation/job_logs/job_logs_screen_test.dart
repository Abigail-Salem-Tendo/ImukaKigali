import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/core/theme/app_theme.dart';
import 'package:imuka_kigali/domain/repositories/auth_repository.dart';
import 'package:imuka_kigali/domain/repositories/driver_job_repository.dart';
import 'package:imuka_kigali/presentation/screens/job_logs/job_logs_bloc.dart';
import 'package:imuka_kigali/presentation/screens/job_logs/job_logs_screen.dart';
import 'package:imuka_kigali/presentation/screens/job_logs/job_logs_summary_card.dart';
import 'package:imuka_kigali/presentation/screens/login/auth_bloc.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  late FakeDriverJobRepository jobRepo;
  late FakeAuthRepository authRepo;
  late AuthBloc authBloc;

  setUp(() {
    jobRepo = FakeDriverJobRepository();
    authRepo = FakeAuthRepository()
      ..signedIn = testUser(driverId, 'Jean Driver', role: UserRoles.driver);
    authBloc = AuthBloc(authRepo);
  });

  tearDown(() => authBloc.close());

  // The screen reads the driver's uid once when it opens, so AuthBloc must
  // already know who is signed in.
  Future<void> openScreen(WidgetTester tester) async {
    await tester.runAsync(() async {
      final signedIn = authBloc.stream.firstWhere((s) => s.user != null);
      authBloc.add(const AuthCheckRequested());
      await signedIn;
    });
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<DriverJobRepository>.value(value: jobRepo),
          RepositoryProvider<AuthRepository>.value(value: authRepo),
        ],
        child: BlocProvider.value(
          value: authBloc,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const JobLogsScreen(),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the empty state when I have no jobs', (tester) async {
    await openScreen(tester);
    expect(jobRepo.watchedDriverId, driverId);

    jobRepo.myJobs.add([]);
    await tester.pump();
    await tester.pump();

    expect(find.text('No jobs yet'), findsOneWidget);
    expect(find.text('Jobs you accept will show up here.'), findsOneWidget);
    expect(find.text('Find jobs'), findsOneWidget);
    expect(find.text('Recent dispatch jobs'), findsNothing);
  });

  testWidgets('shows the error snackbar once, not on every later change', (
    tester,
  ) async {
    await openScreen(tester);
    jobRepo.myJobs.addError(Exception('Could not load jobs'));
    await tester.pump();
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text('Could not load jobs'),
      ),
      findsOneWidget,
    );

    ScaffoldMessenger.of(tester.element(find.byType(Scaffold)))
        .clearSnackBars();
    await tester.pumpAndSettle();

    // A new state whose status is still failure must not repeat the snackbar.
    tester
        .element(find.byType(Scaffold))
        .read<JobLogsBloc>()
        .add(const JobLogsPeriodChanged(JobLogsPeriod.thisWeek));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('shows my jobs, and This Week changes the list and summary', (
    tester,
  ) async {
    // Tall enough that every card is built, since ListView only builds
    // the cards that are on screen.
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    authRepo
      ..users['client1'] = testUser('client1', 'Diane Uwase')
      ..users['client2'] = testUser('client2', 'Eric Mugisha');
    final now = DateTime.now();
    final jobs = [
      testJob(
        id: 'acc1',
        clientId: 'client1',
        status: RequestStatus.accepted,
        amount: 24000,
        createdAt: now,
      ),
      testJob(id: 'done', clientId: 'client2', amount: 15000, createdAt: now),
      testJob(
        id: 'week',
        clientId: 'client2',
        amount: 32000,
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      testJob(
        id: 'old4',
        clientId: 'no-profile',
        amount: 21000,
        createdAt: now.subtract(const Duration(days: 40)),
      ),
    ];

    await openScreen(tester);
    jobRepo.myJobs.add(jobs);
    await tester.pumpAndSettle();

    Finder inSummary(String text) => find.descendant(
      of: find.byType(JobLogsSummaryCard),
      matching: find.text(text),
    );

    expect(find.text('#IMK-ACC1'), findsOneWidget);
    expect(find.text('#IMK-DONE'), findsOneWidget);
    expect(find.text('#IMK-WEEK'), findsOneWidget);
    expect(find.text('#IMK-OLD4'), findsOneWidget);
    expect(find.text('Diane Uwase'), findsOneWidget);
    expect(find.text('Eric Mugisha'), findsNWidgets(2));
    expect(find.text('Client'), findsOneWidget);
    expect(find.text('Continue delivery'), findsOneWidget);
    expect(inSummary('TOTAL LIFETIME GROSS'), findsOneWidget);
    expect(inSummary('68,000 RWF'), findsOneWidget);
    expect(inSummary('3 Moves'), findsOneWidget);
    expect(inSummary('1 Move'), findsOneWidget);

    await tester.tap(find.text('This Week'));
    await tester.pumpAndSettle();

    expect(find.text('#IMK-ACC1'), findsOneWidget);
    expect(find.text('#IMK-DONE'), findsOneWidget);
    expect(find.text('#IMK-WEEK'), findsNothing);
    expect(find.text('#IMK-OLD4'), findsNothing);
    expect(find.text('Client'), findsNothing);
    expect(find.text('Continue delivery'), findsOneWidget);
    expect(inSummary('GROSS THIS WEEK'), findsOneWidget);
    expect(inSummary('15,000 RWF'), findsOneWidget);
    expect(inSummary('1 Move'), findsNWidgets(2));
  });
}
