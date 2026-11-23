import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/domain/entities/vehicle.dart';
import 'package:imuka_kigali/core/theme/app_theme.dart';
import 'package:imuka_kigali/domain/repositories/auth_repository.dart';
import 'package:imuka_kigali/domain/repositories/request_repository.dart';
import 'package:imuka_kigali/domain/repositories/vehicle_repository.dart';
import 'package:imuka_kigali/presentation/screens/driver_contact/driver_contact_screen.dart';

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

/// Widget tests for the driver contact screen: what the client sees once a
/// driver has accepted, and what they see when something is missing.
void main() {
  late FakeRequestRepository requests;
  late FakeAuthRepository users;
  late FakeVehicleRepository vehicles;

  setUp(() {
    requests = FakeRequestRepository(dealRequest());
    users = FakeAuthRepository()
      ..users['driver1'] = testUser(
        'driver1',
        'Jean Driver',
        role: UserRoles.driver,
      );
    vehicles = FakeVehicleRepository()..stored = _vehicle;
  });

  Future<void> openScreen(
    WidgetTester tester, {
    Size size = const Size(411, 1200),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: AppRoutes.driverContactPath('r1'),
      routes: [
        GoRoute(
          path: AppRoutes.driverContact,
          builder: (context, state) => DriverContactScreen(
            requestId: state.pathParameters['requestId']!,
          ),
        ),
        GoRoute(
          path: AppRoutes.delivery,
          builder: (context, state) =>
              const Scaffold(body: Text('delivery page')),
        ),
        GoRoute(
          path: AppRoutes.findingDriver,
          builder: (context, state) =>
              const Scaffold(body: Text('finding page')),
        ),
        GoRoute(
          path: AppRoutes.whereFromTo,
          builder: (context, state) => const Scaffold(body: Text('home page')),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<RequestRepository>.value(value: requests),
          RepositoryProvider<AuthRepository>.value(value: users),
          RepositoryProvider<VehicleRepository>.value(value: vehicles),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('a driver has accepted', () {
    testWidgets('shows the driver, the vehicle and the fixed price', (
      tester,
    ) async {
      await openScreen(tester);

      expect(find.text('A driver accepted your request'), findsOneWidget);
      expect(find.text('Jean Driver'), findsOneWidget);
      expect(find.text('0788000000'), findsOneWidget);
      expect(find.text('Gasabo'), findsOneWidget);
      expect(find.text('RAD 428 E'), findsOneWidget);
      expect(find.text('Kimironko → Nyamirambo'), findsOneWidget);
      expect(find.text('12,500 RWF'), findsOneWidget);
      expect(find.text('Continue to delivery'), findsOneWidget);
    });

    testWidgets('continue goes to the delivery screen', (tester) async {
      await openScreen(tester);

      await tester.tap(find.text('Continue to delivery'));
      await tester.pumpAndSettle();

      expect(find.text('delivery page'), findsOneWidget);
    });

    testWidgets('copy puts the phone number on the clipboard', (tester) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await openScreen(tester);

      await tester.tap(find.byTooltip('Copy phone number'));
      await tester.pumpAndSettle();

      final copy = calls.firstWhere((c) => c.method == 'Clipboard.setData');
      expect((copy.arguments as Map)['text'], '0788000000');
      expect(find.text('Phone number copied'), findsOneWidget);
    });

    testWidgets('a driver who accepts while the screen is open appears live', (
      tester,
    ) async {
      requests = FakeRequestRepository(
        dealRequest(driverId: '', status: RequestStatus.open),
      );
      await openScreen(tester);
      expect(find.text('No driver yet'), findsOneWidget);

      requests.emit(dealRequest());
      await tester.pumpAndSettle();

      expect(find.text('Jean Driver'), findsOneWidget);
      expect(find.text('No driver yet'), findsNothing);
    });
  });

  group('when something is missing', () {
    testWidgets('a driver with no saved vehicle shows the requested type', (
      tester,
    ) async {
      vehicles.stored = null;
      await openScreen(tester);

      expect(find.text('Jean Driver'), findsOneWidget);
      expect(find.text('Plate not available'), findsOneWidget);
    });

    testWidgets('a profile that cannot load says so and can be retried', (
      tester,
    ) async {
      users.failingUserIds.add('driver1');
      await openScreen(tester);

      expect(find.text('Jean Driver'), findsNothing);
      // Shown on the screen and in a snackbar.
      expect(find.text('No permission'), findsWidgets);
      // The price is still there.
      expect(find.text('12,500 RWF'), findsOneWidget);

      users.failingUserIds.clear();
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Jean Driver'), findsOneWidget);
    });

    testWidgets('no driver yet sends the client back to the search', (
      tester,
    ) async {
      requests = FakeRequestRepository(
        dealRequest(driverId: '', status: RequestStatus.open),
      );
      await openScreen(tester);

      await tester.tap(find.text('Back to search'));
      await tester.pumpAndSettle();

      expect(find.text('finding page'), findsOneWidget);
    });

    testWidgets('a cancelled request offers a new one', (tester) async {
      requests = FakeRequestRepository(
        dealRequest(status: RequestStatus.cancelled),
      );
      await openScreen(tester);

      expect(find.text('This request was cancelled'), findsOneWidget);
      await tester.tap(find.text('New request'));
      await tester.pumpAndSettle();

      expect(find.text('home page'), findsOneWidget);
    });

    testWidgets('a request that is gone shows an error with retry', (
      tester,
    ) async {
      requests = FakeRequestRepository(null);
      await openScreen(tester);

      expect(find.text('Request not found'), findsWidgets);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('screen sizes', () {
    for (final size in const [
      Size(360, 640),
      Size(411, 891),
      Size(800, 360),
      Size(915, 412),
    ]) {
      testWidgets('no overflow at ${size.width}x${size.height}', (
        tester,
      ) async {
        await openScreen(tester, size: size);

        expect(tester.takeException(), isNull);
        expect(find.text('Jean Driver'), findsOneWidget);
      });
    }
  });
}
