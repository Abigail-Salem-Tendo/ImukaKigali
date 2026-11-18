import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/core/theme/app_theme.dart';
import 'package:imuka_kigali/domain/repositories/auth_repository.dart';
import 'package:imuka_kigali/domain/repositories/driver_job_repository.dart';
import 'package:imuka_kigali/presentation/screens/job_logs/job_logs_screen.dart';
import 'package:imuka_kigali/presentation/screens/login/auth_bloc.dart';

import 'job_logs_fakes.dart';

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
}
