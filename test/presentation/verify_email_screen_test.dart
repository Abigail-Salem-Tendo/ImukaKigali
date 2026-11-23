import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/core/theme/app_theme.dart';
import 'package:imuka_kigali/domain/entities/app_user.dart';
import 'package:imuka_kigali/presentation/screens/login/auth_bloc.dart';
import 'package:imuka_kigali/presentation/screens/verify_email/verify_email_screen.dart';

import '../helpers/recording_auth_repository.dart';

void main() {
  late RecordingAuthRepository repo;
  late AuthBloc bloc;

  setUp(() {
    repo = RecordingAuthRepository()
      ..signedIn = AppUser(
        uid: 'u1',
        role: UserRoles.client,
        fullName: 'Diane Uwase',
        phone: '+250781234567',
        email: 'diane@example.com',
        district: 'Kicukiro',
        createdAt: DateTime(2026),
      );
  });

  // Starts the screen with Diane signed in but not verified yet, the way
  // the router would show it.
  Future<void> showScreen(WidgetTester tester) async {
    // The bloc is made here, inside the test, not in setUp(): widget tests
    // run on a fake clock, and a bloc made outside it never gets to work.
    bloc = AuthBloc(repo)..add(const AuthCheckRequested());
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const VerifyEmailScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the address the link was sent to', (tester) async {
    await showScreen(tester);

    expect(find.text('Check your inbox'), findsOneWidget);
    expect(find.textContaining('diane@example.com'), findsOneWidget);
  });

  testWidgets('"I\'ve verified" before clicking the link shows an error', (
    tester,
  ) async {
    await showScreen(tester);
    await tapText(tester, "I've verified my email");

    expect(find.textContaining('Not verified yet'), findsOneWidget);
    expect(bloc.state.emailVerified, isFalse);
  });

  testWidgets('"I\'ve verified" after clicking the link verifies the user', (
    tester,
  ) async {
    await showScreen(tester);
    repo.verified = true;
    await tapText(tester, "I've verified my email");

    expect(bloc.state.emailVerified, isTrue);
  });

  testWidgets('Resend sends a new email and says so', (tester) async {
    await showScreen(tester);
    await tapText(tester, 'Resend email');

    expect(repo.verificationEmailsSent, 1);
    expect(find.textContaining('We sent a new link'), findsOneWidget);
  });

  testWidgets('"Use a different account" logs out', (tester) async {
    await showScreen(tester);
    await tapText(tester, 'Use a different account');

    expect(repo.signOutCalls, 1);
    expect(bloc.state.status, AuthStatus.unauthenticated);
  });
}
