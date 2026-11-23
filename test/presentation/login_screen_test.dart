import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/theme/app_theme.dart';
import 'package:imuka_kigali/presentation/screens/login/auth_bloc.dart';
import 'package:imuka_kigali/presentation/screens/login/login_screen.dart';

import '../helpers/recording_auth_repository.dart';

void main() {
  late RecordingAuthRepository repo;

  setUp(() => repo = RecordingAuthRepository());

  // Like the real app: the session check runs first (nobody is signed in
  // here), and the form appears once it has finished.
  Future<void> showLoginScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AuthBloc(repo)..add(const AuthCheckRequested()),
        child: MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows a spinner, not the form, while checking the session', (
    tester,
  ) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AuthBloc(repo),
        child: MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Welcome Back'), findsNothing);
  });

  // The fields are found by order: email first, password second.
  Finder emailField() => find.byType(TextFormField).at(0);
  Finder passwordField() => find.byType(TextFormField).at(1);

  Future<void> tapText(WidgetTester tester, String text) async {
    // The test screen is small, so scroll the button into view first.
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets('empty form shows errors and does not try to log in', (
    tester,
  ) async {
    await showLoginScreen(tester);
    await tapText(tester, 'Log In to Imuka Kigali');

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(repo.signInEmails, isEmpty);
  });

  testWidgets('valid form logs in with the trimmed email', (tester) async {
    await showLoginScreen(tester);
    await tester.enterText(emailField(), '  diane@example.com ');
    await tester.enterText(passwordField(), 'kigali2026');
    await tapText(tester, 'Log In to Imuka Kigali');

    expect(repo.signInEmails, ['diane@example.com']);
  });

  testWidgets('a failed login shows the error in a snackbar', (tester) async {
    repo.failWith = 'Incorrect email or password.';
    await showLoginScreen(tester);
    await tester.enterText(emailField(), 'diane@example.com');
    await tester.enterText(passwordField(), 'wrong');
    await tapText(tester, 'Log In to Imuka Kigali');

    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });

  testWidgets('forgot password without an email asks for one first', (
    tester,
  ) async {
    await showLoginScreen(tester);
    await tapText(tester, 'Forgot password?');

    expect(find.textContaining('Type your email above first'), findsOneWidget);
    expect(repo.resetEmails, isEmpty);
  });

  testWidgets('forgot password with an email sends the reset link', (
    tester,
  ) async {
    await showLoginScreen(tester);
    await tester.enterText(emailField(), 'diane@example.com');
    await tapText(tester, 'Forgot password?');

    expect(repo.resetEmails, ['diane@example.com']);
    expect(find.textContaining('We sent a reset link'), findsOneWidget);
  });
}
