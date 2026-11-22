import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/core/theme/app_theme.dart';
import 'package:imuka_kigali/domain/repositories/payment_repository.dart';
import 'package:imuka_kigali/domain/repositories/request_repository.dart';
import 'package:imuka_kigali/presentation/screens/delivery_handshake_payment/delivery_handshake_payment_screen.dart';
import 'package:imuka_kigali/presentation/screens/login/auth_bloc.dart';

import '../helpers/fake_payment_repository.dart';
import '../helpers/fake_repositories.dart';
import '../helpers/fake_request_repository.dart';

/// Widget tests for the delivery screen: what the client and the driver see,
/// and the whole handshake and payment flow.
void main() {
  late FakeRequestRepository requests;
  late FakePaymentRepository payments;
  late FakeAuthRepository authRepo;
  late AuthBloc authBloc;

  setUp(() {
    requests = FakeRequestRepository(dealRequest());
    payments = FakePaymentRepository();
    authRepo = FakeAuthRepository();
    authBloc = AuthBloc(authRepo);
  });

  tearDown(() => authBloc.close());

  /// Opens the screen as the client or the driver, with a router so the
  /// "Rate your driver" button has somewhere to go.
  Future<void> openScreen(
    WidgetTester tester, {
    required bool asClient,
    Size size = const Size(411, 1600),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    authRepo.signedIn = asClient
        ? testUser('client1', 'Diane Uwase')
        : testUser('driver1', 'Jean Driver', role: UserRoles.driver);
    await tester.runAsync(() async {
      authBloc.add(const AuthCheckRequested());
      await authBloc.stream.firstWhere((s) => s.user != null);
    });

    final router = GoRouter(
      initialLocation: AppRoutes.deliveryPath('r1'),
      routes: [
        GoRoute(
          path: AppRoutes.delivery,
          builder: (context, state) => DeliveryHandshakePaymentScreen(
            requestId: state.pathParameters['requestId']!,
          ),
        ),
        GoRoute(
          path: AppRoutes.rate,
          builder: (context, state) => const Scaffold(body: Text('rate page')),
        ),
        GoRoute(
          path: AppRoutes.driverJobs,
          builder: (context, state) => const Scaffold(body: Text('jobs page')),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<RequestRepository>.value(value: requests),
          RepositoryProvider<PaymentRepository>.value(value: payments),
        ],
        child: BlocProvider.value(
          value: authBloc,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool isEnabled(WidgetTester tester, String label) {
    final button = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text(label),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    return button.onPressed != null;
  }

  group('what each side sees', () {
    testWidgets('the client sees the trip, the price and the payment card', (
      tester,
    ) async {
      await openScreen(tester, asClient: true);

      expect(find.text('Kimironko → Nyamirambo'), findsOneWidget);
      expect(find.text('12,500 RWF'), findsOneWidget);
      expect(find.text('Handshake'), findsOneWidget);
      expect(find.text('Payment'), findsOneWidget);
      expect(find.text('MTN MoMo'), findsOneWidget);
      expect(find.text('Airtel Money'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(isEnabled(tester, 'Pay 12,500 RWF'), isFalse);
    });

    testWidgets('the driver sees the handshake but cannot pay', (tester) async {
      await openScreen(tester, asClient: false);

      expect(find.text('Handshake'), findsOneWidget);
      expect(find.text('You (driver)'), findsOneWidget);
      expect(find.text('Payment'), findsNothing);
      expect(find.text('MTN MoMo'), findsNothing);
      expect(find.textContaining('Waiting for the client to pay'), findsOne);
    });

    testWidgets('a cancelled request has nothing to hand over or pay', (
      tester,
    ) async {
      requests = FakeRequestRepository(
        dealRequest(status: RequestStatus.cancelled),
      );
      await openScreen(tester, asClient: true);

      expect(find.text('This request was cancelled'), findsOneWidget);
      expect(find.text('Handshake'), findsNothing);
    });
  });

  group('handshake and payment', () {
    testWidgets('confirming shows "You confirmed" and tells the other side', (
      tester,
    ) async {
      await openScreen(tester, asClient: true);

      await tester.tap(find.text('Confirm handover'));
      await tester.pumpAndSettle();

      expect(find.text('You confirmed'), findsOneWidget);
      expect(requests.updates, [
        {Fields.clientConfirmed: true},
      ]);
    });

    testWidgets('the driver confirming shows up on the client screen live', (
      tester,
    ) async {
      await openScreen(tester, asClient: true);
      expect(find.text('Waiting'), findsNWidgets(2));

      requests.emit(dealRequest(driverConfirmed: true));
      await tester.pumpAndSettle();

      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Waiting'), findsOneWidget);
    });

    testWidgets('pay stays off until both confirmed and a method is chosen', (
      tester,
    ) async {
      requests = FakeRequestRepository(dealRequest(driverConfirmed: true));
      await openScreen(tester, asClient: true);

      await tester.tap(find.text('MTN MoMo'));
      await tester.pumpAndSettle();
      expect(isEnabled(tester, 'Pay 12,500 RWF'), isFalse);

      await tester.tap(find.text('Confirm handover'));
      await tester.pumpAndSettle();
      expect(isEnabled(tester, 'Pay 12,500 RWF'), isTrue);
    });

    testWidgets('the whole deal: confirm, choose, pay, then rate', (
      tester,
    ) async {
      requests = FakeRequestRepository(dealRequest(driverConfirmed: true));
      await openScreen(tester, asClient: true);

      await tester.tap(find.text('Confirm handover'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('MTN MoMo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pay 12,500 RWF'));
      await tester.pumpAndSettle();

      expect(find.text('Payment complete'), findsOneWidget);
      expect(find.text('12,500 RWF by MTN MoMo'), findsOneWidget);
      expect(payments.saved!.status, PaymentStatus.paid);
      expect(payments.saved!.amount, 12500);
      expect(requests.updates.last, {Fields.status: RequestStatus.completed});

      await tester.tap(find.text('Rate your driver'));
      await tester.pumpAndSettle();
      expect(find.text('rate page'), findsOneWidget);
    });

    testWidgets('the driver sees the payment complete without refreshing', (
      tester,
    ) async {
      requests = FakeRequestRepository(
        dealRequest(clientConfirmed: true, driverConfirmed: true),
      );
      await openScreen(tester, asClient: false);
      expect(find.text('Payment complete'), findsNothing);

      requests.emit(
        dealRequest(
          status: RequestStatus.completed,
          clientConfirmed: true,
          driverConfirmed: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Payment complete'), findsOneWidget);
      await tester.tap(find.text('Back to my jobs'));
      await tester.pumpAndSettle();
      expect(find.text('jobs page'), findsOneWidget);
    });

    testWidgets('a failed save shows a polite message and nothing is paid', (
      tester,
    ) async {
      requests = FakeRequestRepository(dealRequest(driverConfirmed: true));
      await openScreen(tester, asClient: true);
      requests.failUpdateWith = 'You are not allowed to do that';

      await tester.tap(find.text('Confirm handover'));
      await tester.pumpAndSettle();

      expect(find.text('You are not allowed to do that'), findsOneWidget);
      expect(find.text('Confirm handover'), findsOneWidget);
      expect(payments.createCalls, 0);
    });
  });

  group('screen sizes', () {
    for (final size in const [
      Size(360, 640),
      Size(411, 891),
      Size(800, 360),
      Size(915, 412),
    ]) {
      testWidgets(
        'client screen has no overflow at ${size.width}x${size.height}',
        (tester) async {
          await openScreen(tester, asClient: true, size: size);

          expect(tester.takeException(), isNull);
          expect(find.text('Handshake'), findsOneWidget);
        },
      );
    }

    testWidgets('driver screen has no overflow in landscape', (tester) async {
      await openScreen(tester, asClient: false, size: const Size(800, 360));

      expect(tester.takeException(), isNull);
    });
  });
}
