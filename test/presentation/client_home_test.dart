import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/core/theme/app_theme.dart';
import 'package:imuka_kigali/domain/entities/app_user.dart';
import 'package:imuka_kigali/domain/entities/move_request.dart';
import 'package:imuka_kigali/domain/repositories/request_repository.dart';
import 'package:imuka_kigali/presentation/screens/client_home/client_home_bloc.dart';
import 'package:imuka_kigali/presentation/screens/client_home/client_home_screen.dart';
import 'package:imuka_kigali/presentation/screens/login/auth_bloc.dart';

import '../helpers/recording_auth_repository.dart';

/// Only watchMyRequests is used by the client home. The test pushes lists
/// (or an error) into [moves] to play the part of Firestore.
class _FakeRequestRepository implements RequestRepository {
  final moves = StreamController<List<MoveRequest>>();
  String? watchedClientId;

  @override
  Stream<List<MoveRequest>> watchMyRequests(String clientId) {
    watchedClientId = clientId;
    return moves.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

MoveRequest _move({required String status}) => MoveRequest(
  id: 'r1',
  clientId: 'u1',
  driverId: '',
  pickupLocation: 'Kacyiru',
  dropoffLocation: 'Nyamirambo',
  itemDescription: 'Sofa and fridge',
  vehicleType: 'pickup',
  estimatedMinutes: 30,
  proposedAmount: 12500,
  status: status,
  clientConfirmed: false,
  driverConfirmed: false,
  createdAt: DateTime(2026, 11, 20, 9),
);

void main() {
  group('ClientHomeBloc', () {
    test('shows the moves Firestore sends', () async {
      final repo = _FakeRequestRepository();
      final bloc = ClientHomeBloc(repo)..add(const ClientHomeStarted('u1'));
      addTearDown(bloc.close);

      repo.moves.add([_move(status: RequestStatus.open)]);
      final done = await bloc.stream.firstWhere(
        (s) => s.status == ClientHomeStatus.success,
      );
      expect(repo.watchedClientId, 'u1');
      expect(done.moves, hasLength(1));
    });

    test('a Firestore error becomes a readable message', () async {
      final repo = _FakeRequestRepository();
      final bloc = ClientHomeBloc(repo)..add(const ClientHomeStarted('u1'));
      addTearDown(bloc.close);

      repo.moves.addError(Exception('No internet connection'));
      final done = await bloc.stream.firstWhere(
        (s) => s.status == ClientHomeStatus.failure,
      );
      expect(done.error, 'No internet connection');
    });
  });

  group('ClientHomeScreen', () {
    late RecordingAuthRepository auth;
    late _FakeRequestRepository requests;

    setUp(() {
      auth = RecordingAuthRepository()
        ..verified = true
        ..signedIn = AppUser(
          uid: 'u1',
          role: UserRoles.client,
          fullName: 'Diane Uwase',
          phone: '+250781234567',
          email: 'diane@example.com',
          district: 'Kicukiro',
          createdAt: DateTime(2026),
        );
      requests = _FakeRequestRepository();
    });

    // Diane is signed in. The pages the home links to are stand-ins, so a
    // test can see where a tap went.
    Future<void> showHome(WidgetTester tester) async {
      // Made inside the test, not in setUp(): widget tests run on a fake
      // clock, and a bloc made outside it never gets to work.
      final authBloc = AuthBloc(auth)..add(const AuthCheckRequested());
      addTearDown(authBloc.close);
      final router = GoRouter(
        initialLocation: AppRoutes.clientHome,
        routes: [
          GoRoute(
            path: AppRoutes.clientHome,
            builder: (_, _) => const ClientHomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.whereFromTo,
            builder: (_, _) => const Text('Where to page'),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (_, _) => const Text('Settings page'),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        RepositoryProvider<RequestRepository>.value(
          value: requests,
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

    testWidgets('greets the client by first name', (tester) async {
      await showHome(tester);
      expect(find.text('Hi Diane 👋'), findsOneWidget);
    });

    testWidgets('with no moves yet, says so', (tester) async {
      await showHome(tester);
      requests.moves.add([]);
      await tester.pumpAndSettle();

      expect(find.text('No moves yet'), findsOneWidget);
    });

    testWidgets('lists each move with its route, status and price', (
      tester,
    ) async {
      await showHome(tester);
      requests.moves.add([_move(status: RequestStatus.open)]);
      await tester.pumpAndSettle();

      expect(find.text('Kacyiru → Nyamirambo'), findsOneWidget);
      expect(find.text('Finding driver'), findsOneWidget);
      expect(find.text('12,500 RWF'), findsOneWidget);
    });

    testWidgets('"Book a move" opens "Where to?"', (tester) async {
      await showHome(tester);
      await tester.tap(find.text('Book a move'));
      await tester.pumpAndSettle();

      expect(find.text('Where to page'), findsOneWidget);
    });

    testWidgets('the account menu shows who is signed in and logs out', (
      tester,
    ) async {
      await showHome(tester);
      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();

      expect(find.text('diane@example.com'), findsOneWidget);
      await tester.tap(find.text('Log out'));
      // Not pumpAndSettle: with no real router here to move on to Login,
      // the "logging out" spinner keeps turning.
      await tester.pump(const Duration(seconds: 1));

      expect(auth.signOutCalls, 1);
    });
  });
}
