import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/core/theme/app_theme.dart';
import 'package:imuka_kigali/domain/entities/rating.dart';
import 'package:imuka_kigali/domain/repositories/rating_repository.dart';
import 'package:imuka_kigali/domain/repositories/request_repository.dart';
import 'package:imuka_kigali/presentation/screens/login/auth_bloc.dart';
import 'package:imuka_kigali/presentation/screens/rate_driver/rate_driver_screen.dart';

import '../helpers/fake_rating_repository.dart';
import '../helpers/fake_repositories.dart';
import '../helpers/fake_request_repository.dart';

/// Widget tests for the rating screen: what the client sees and the whole
/// create, update and delete flow.
void main() {
  late FakeRequestRepository requests;
  late FakeRatingRepository ratings;
  late FakeAuthRepository authRepo;
  late AuthBloc authBloc;

  setUp(() {
    requests = FakeRequestRepository(
      dealRequest(status: RequestStatus.completed),
    );
    ratings = FakeRatingRepository();
    authRepo = FakeAuthRepository();
    authBloc = AuthBloc(authRepo);
  });

  tearDown(() => authBloc.close());

  Future<void> openScreen(
    WidgetTester tester, {
    bool asClient = true,
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
      initialLocation: AppRoutes.ratePath('r1'),
      routes: [
        GoRoute(
          path: AppRoutes.rate,
          builder: (context, state) =>
              RateDriverScreen(requestId: state.pathParameters['requestId']!),
        ),
        GoRoute(
          path: AppRoutes.whereFromTo,
          builder: (context, state) => const Scaffold(body: Text('home page')),
        ),
        GoRoute(
          path: AppRoutes.delivery,
          builder: (context, state) =>
              const Scaffold(body: Text('delivery page')),
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
          RepositoryProvider<RatingRepository>.value(value: ratings),
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

  Future<void> tapStar(WidgetTester tester, int value) async {
    await tester.tap(find.byTooltip('$value ${value == 1 ? 'star' : 'stars'}'));
    await tester.pumpAndSettle();
  }

  group('what the client sees', () {
    testWidgets('five stars and a submit that waits for a star', (
      tester,
    ) async {
      await openScreen(tester);

      expect(find.text('How was your delivery?'), findsOneWidget);
      expect(find.text('Kimironko → Nyamirambo'), findsOneWidget);
      for (var value = 2; value <= 5; value++) {
        expect(find.byTooltip('$value stars'), findsOneWidget);
      }
      expect(find.byTooltip('1 star'), findsOneWidget);
      expect(find.text('Tap a star to rate'), findsOneWidget);
      expect(isEnabled(tester, 'Submit rating'), isFalse);
      expect(find.text('Remove rating'), findsNothing);
    });

    testWidgets('tapping a star names it and opens submit', (tester) async {
      await openScreen(tester);

      await tapStar(tester, 4);

      expect(find.text('Very good'), findsOneWidget);
      expect(isEnabled(tester, 'Submit rating'), isTrue);
    });

    testWidgets('an existing rating is shown so it can be changed', (
      tester,
    ) async {
      ratings.saved = Rating(
        id: 'r1',
        requestId: 'r1',
        clientId: 'client1',
        driverId: 'driver1',
        stars: 5,
        comment: 'Careful with the sofa',
        createdAt: DateTime(2026),
      );
      await openScreen(tester);

      expect(find.text('Excellent'), findsOneWidget);
      expect(find.text('Careful with the sofa'), findsOneWidget);
      expect(find.text('Update rating'), findsOneWidget);
      expect(find.text('Remove rating'), findsOneWidget);
      expect(isEnabled(tester, 'Update rating'), isFalse);
    });

    testWidgets('before the payment the client is sent back to it', (
      tester,
    ) async {
      requests = FakeRequestRepository(dealRequest());
      await openScreen(tester);

      expect(find.text('You can rate after paying'), findsOneWidget);
      expect(find.byTooltip('5 stars'), findsNothing);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('delivery page'), findsOneWidget);
    });

    testWidgets('the driver cannot rate', (tester) async {
      await openScreen(tester, asClient: false);

      expect(find.text('Only the client rates the driver'), findsOneWidget);
      expect(find.byTooltip('5 stars'), findsNothing);
    });

    testWidgets('a request that cannot load shows a retry that works', (
      tester,
    ) async {
      requests.failGetWith = 'No internet connection';
      await openScreen(tester);
      // Shown on the screen and in a snackbar.
      expect(find.text('No internet connection'), findsWidgets);

      requests.failGetWith = null;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('How was your delivery?'), findsOneWidget);
    });
  });

  group('create, update and delete', () {
    testWidgets('rate, change and remove, with a message each time', (
      tester,
    ) async {
      await openScreen(tester);

      // Create
      await tapStar(tester, 5);
      await tester.enterText(find.byType(TextField), 'Careful with the sofa');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit rating'));
      await tester.pumpAndSettle();

      expect(find.text('Thanks for rating your driver'), findsOneWidget);
      expect(ratings.saved!.stars, 5);
      expect(ratings.saved!.comment, 'Careful with the sofa');
      expect(ratings.saved!.driverId, 'driver1');
      expect(find.text('Update rating'), findsOneWidget);
      expect(find.text('Remove rating'), findsOneWidget);

      // Update
      await tapStar(tester, 2);
      expect(isEnabled(tester, 'Update rating'), isTrue);
      await tester.tap(find.text('Update rating'));
      await tester.pumpAndSettle();

      expect(find.text('Your rating was updated'), findsOneWidget);
      expect(ratings.saved!.stars, 2);
      expect(ratings.createCalls, 1);

      // Delete
      await tester.tap(find.text('Remove rating'));
      await tester.pumpAndSettle();
      expect(find.text('Remove your rating?'), findsOneWidget);
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(find.text('Your rating was removed'), findsOneWidget);
      expect(ratings.saved, isNull);
      expect(find.text('Submit rating'), findsOneWidget);
      expect(find.text('Tap a star to rate'), findsOneWidget);
    });

    testWidgets('keeping the rating in the dialog deletes nothing', (
      tester,
    ) async {
      await openScreen(tester);
      await tapStar(tester, 3);
      await tester.tap(find.text('Submit rating'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remove rating'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep it'));
      await tester.pumpAndSettle();

      expect(ratings.deleteCalls, 0);
      expect(ratings.saved!.stars, 3);
    });

    testWidgets('a failed save shows a polite message and keeps the stars', (
      tester,
    ) async {
      await openScreen(tester);
      await tapStar(tester, 4);
      ratings.failWith = 'You are not allowed to rate this request';

      await tester.tap(find.text('Submit rating'));
      await tester.pumpAndSettle();

      expect(
        find.text('You are not allowed to rate this request'),
        findsOneWidget,
      );
      expect(find.text('Very good'), findsOneWidget);
      expect(ratings.saved, isNull);
    });

    testWidgets('skip goes back to the start', (tester) async {
      await openScreen(tester);

      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();

      expect(find.text('home page'), findsOneWidget);
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
        expect(find.text('How was your delivery?'), findsOneWidget);
      });
    }
  });
}
