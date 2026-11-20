import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/core/constants/kigali_districts.dart';
import 'package:imuka_kigali/core/theme/app_theme.dart';
import 'package:imuka_kigali/presentation/screens/create_account/create_account_screen.dart';
import 'package:imuka_kigali/presentation/screens/login/auth_bloc.dart';

import '../helpers/recording_auth_repository.dart';

void main() {
  late RecordingAuthRepository repo;

  setUp(() => repo = RecordingAuthRepository());

  Future<void> showScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AuthBloc(repo),
        child: MaterialApp(
          theme: AppTheme.light,
          home: const CreateAccountScreen(),
        ),
      ),
    );
  }

  // The text fields in screen order.
  Finder field(int index) => find.byType(TextFormField).at(index);
  const name = 0, phone = 1, email = 2, password = 3, confirm = 4;

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  Future<void> fillValidForm(WidgetTester tester) async {
    await tester.enterText(field(name), 'Diane Uwase');
    await tester.enterText(field(phone), '788 123 456');
    await tester.enterText(field(email), 'diane@example.com');
    await tester.enterText(field(password), 'kigali2026');
    await tester.enterText(field(confirm), 'kigali2026');
    await tapText(tester, 'Kicukiro');
  }

  testWidgets('empty form shows every error and registers nobody', (
    tester,
  ) async {
    await showScreen(tester);
    await tapText(tester, 'Create Mover Account');

    expect(find.text('Full name is required'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Choose your district'), findsOneWidget);
    expect(repo.registeredUsers, isEmpty);
  });

  testWidgets('valid form registers a client with the full phone number', (
    tester,
  ) async {
    await showScreen(tester);
    await fillValidForm(tester);
    await tapText(tester, 'Create Mover Account');

    final user = repo.registeredUsers.single;
    expect(user.role, UserRoles.client);
    expect(user.phone, '+250788123456');
    expect(user.district, KigaliDistricts.kicukiro);
  });

  for (final typed in ['0788 123 456', '250 788 123 456', '+250788123456']) {
    testWidgets('phone typed as "$typed" is saved as +250788123456', (
      tester,
    ) async {
      await showScreen(tester);
      await fillValidForm(tester);
      await tester.enterText(field(phone), typed);
      await tapText(tester, 'Create Mover Account');

      expect(repo.registeredUsers.single.phone, '+250788123456');
    });
  }

  testWidgets('different passwords are caught before sign-up', (tester) async {
    await showScreen(tester);
    await fillValidForm(tester);
    await tester.enterText(field(confirm), 'kigali2027');
    await tapText(tester, 'Create Mover Account');

    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(repo.registeredUsers, isEmpty);
  });

  testWidgets('a failed sign-up shows the error in a snackbar', (tester) async {
    repo.failWith = 'An account already exists for that email.';
    await showScreen(tester);
    await fillValidForm(tester);
    await tapText(tester, 'Create Mover Account');

    expect(
      find.text('An account already exists for that email.'),
      findsOneWidget,
    );
  });
}
