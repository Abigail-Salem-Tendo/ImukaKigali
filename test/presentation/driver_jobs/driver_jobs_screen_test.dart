import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/core/constants/pricing.dart';
import 'package:imuka_kigali/core/theme/app_theme.dart';
import 'package:imuka_kigali/domain/entities/vehicle_class.dart';
import 'package:imuka_kigali/domain/repositories/auth_repository.dart';
import 'package:imuka_kigali/domain/repositories/driver_job_repository.dart';
import 'package:imuka_kigali/domain/repositories/vehicle_repository.dart';
import 'package:imuka_kigali/presentation/screens/driver_jobs/driver_jobs_screen.dart';
import 'package:imuka_kigali/presentation/screens/login/auth_bloc.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/fake_vehicle_repository.dart';

void main() {
  // Read from VehicleClasses, so renaming a vehicle doesn't break this test.
  final pickupLabel = VehicleClasses.of(VehicleTypes.pickup).shortLabel;

  late FakeDriverJobRepository jobRepo;
  late FakeAuthRepository authRepo;
  late FakeVehicleRepository vehicleRepo;
  late AuthBloc authBloc;

  setUp(() {
    jobRepo = FakeDriverJobRepository();
    authRepo = FakeAuthRepository()
      ..signedIn = testUser(driverId, 'Jean Driver', role: UserRoles.driver)
      ..users['client1'] = testUser('client1', 'Diane Uwase');
    vehicleRepo = FakeVehicleRepository()..stored = testVehicle();
    authBloc = AuthBloc(authRepo);
  });

  tearDown(() => authBloc.close());

  Future<void> openScreen(WidgetTester tester) async {
    // Tall enough that every card is built, since ListView only builds
    // the cards that are on screen.
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // The screen reads the driver's uid once when it opens, so AuthBloc must
    // already know who is signed in.
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
          RepositoryProvider<VehicleRepository>.value(value: vehicleRepo),
        ],
        child: BlocProvider.value(
          value: authBloc,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const DriverJobsScreen(),
          ),
        ),
      ),
    );
  }

  final jobA = testJob(
    id: 'a8429',
    clientId: 'client1',
    status: RequestStatus.open,
    amount: 24000,
  );
  final jobB = testJob(id: 'b9014', status: RequestStatus.open, amount: 32000);

  testWidgets(
    'shows open jobs and the taken snackbar when someone was faster',
    (tester) async {
      jobRepo.acceptError = 'This job was just taken by another driver';
      await openScreen(tester);
      jobRepo.openJobs.add([jobA, jobB]);
      await tester.pump();
      await tester.pump();

      expect(find.text('Gasabo District Hub'), findsOneWidget);
      expect(find.text('$pickupLabel • Max load 1.5 t'), findsOneWidget);
      expect(find.text('DISPATCH #IMK-A842'), findsOneWidget);
      expect(find.text('DISPATCH #IMK-B901'), findsOneWidget);
      expect(find.text('Accept 24,000 RWF'), findsOneWidget);
      expect(find.text('Accept 32,000 RWF'), findsOneWidget);
      expect(find.text('Counter-Offer / Bid'), findsNothing);

      await tester.tap(find.text('Accept 24,000 RWF'));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('This job was just taken by another driver'),
        findsOneWidget,
      );
      expect(find.text('Job accepted'), findsNothing);
      expect(jobRepo.acceptedIds, ['a8429']);
    },
  );

  testWidgets('shows the taken snackbar once for each failed accept', (
    tester,
  ) async {
    const taken = 'This job was just taken by another driver';
    jobRepo.acceptError = taken;
    Future<void> clearSnackBars() async {
      ScaffoldMessenger.of(tester.element(find.byType(Scaffold)))
          .clearSnackBars();
      await tester.pumpAndSettle();
    }

    await openScreen(tester);
    jobRepo.openJobs.add([jobA, jobB]);
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Accept 24,000 RWF'));
    await tester.pump();
    await tester.pump();
    expect(find.text(taken), findsOneWidget);
    await clearSnackBars();

    jobRepo.openJobs.add([jobB]);
    await tester.pumpAndSettle();
    expect(find.text(taken), findsNothing);

    await tester.tap(find.text('Accept 32,000 RWF'));
    await tester.pump();
    await tester.pump();
    expect(find.text(taken), findsOneWidget);
    expect(jobRepo.acceptedIds, ['a8429', 'b9014']);
  });

  testWidgets('after accepting shows the client contact and delivery button', (
    tester,
  ) async {
    await openScreen(tester);
    jobRepo.openJobs.add([jobA]);
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Accept 24,000 RWF'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Job accepted'), findsWidgets);
    expect(find.text('Diane Uwase'), findsOneWidget);
    expect(find.text('0788000000'), findsOneWidget);
    expect(find.text('Go to delivery'), findsOneWidget);
  });

  testWidgets('a driver without a vehicle is asked to register one', (
    tester,
  ) async {
    vehicleRepo.stored = null;
    await openScreen(tester);
    await tester.pump();

    expect(find.text('Add your vehicle first'), findsOneWidget);
    expect(find.text('Register vehicle'), findsOneWidget);
    expect(jobRepo.watchedVehicleType, isNull);
  });
}
