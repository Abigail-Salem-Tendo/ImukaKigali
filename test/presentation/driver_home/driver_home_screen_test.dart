import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/core/theme/app_theme.dart';
import 'package:imuka_kigali/domain/repositories/auth_repository.dart';
import 'package:imuka_kigali/domain/repositories/driver_job_repository.dart';
import 'package:imuka_kigali/domain/repositories/vehicle_repository.dart';
import 'package:imuka_kigali/presentation/screens/driver_home/driver_home_screen.dart';
import 'package:imuka_kigali/presentation/screens/login/auth_bloc.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  late FakeDriverJobRepository jobRepo;
  late FakeAuthRepository authRepo;
  late FakeVehicleRepository vehicleRepo;
  late AuthBloc authBloc;

  setUp(() {
    jobRepo = FakeDriverJobRepository();
    authRepo = FakeAuthRepository()
      ..signedIn = testUser(driverId, 'Jean Driver', role: UserRoles.driver);
    vehicleRepo = FakeVehicleRepository()..vehicle = testVehicle();
    authBloc = AuthBloc(authRepo);
  });

  tearDown(() => authBloc.close());

  // The screen reads the driver's uid once when it opens, so AuthBloc must
  // already know who is signed in.
  Future<void> openScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

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
            home: const DriverHomeScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('a driver without a vehicle gets a button to register one', (
    tester,
  ) async {
    vehicleRepo.vehicle = null;
    await openScreen(tester);

    expect(find.text('Add your vehicle first'), findsOneWidget);
    expect(find.text('Register vehicle'), findsOneWidget);
    expect(find.text('Upcoming accepted moves'), findsNothing);
  });

  testWidgets('shows the open job count, my earnings and accepted moves', (
    tester,
  ) async {
    await openScreen(tester);
    jobRepo.openJobs.add([
      testJob(id: 'o1', status: RequestStatus.open),
      testJob(id: 'o2', status: RequestStatus.open),
    ]);
    jobRepo.myJobs.add([
      testJob(id: 'acc', status: RequestStatus.accepted, amount: 12000),
      testJob(id: 'done', amount: 24000),
    ]);
    await tester.pump();
    await tester.pump();

    expect(find.text('2 open jobs for your Pickup'), findsOneWidget);
    expect(find.text('Gasabo District Hub'), findsOneWidget);
    expect(find.text('24,000 RWF'), findsOneWidget);
    expect(find.text('from 1 move'), findsOneWidget);
    expect(find.text('1 accepted'), findsOneWidget);
    expect(find.text('Kimihurura → Remera'), findsOneWidget);
    expect(find.text('12,000 RWF'), findsOneWidget);
    expect(find.text('Pickup • RAD 428 E'), findsOneWidget);
  });
}
