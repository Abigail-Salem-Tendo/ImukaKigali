import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/core/theme/app_theme.dart';
import 'package:imuka_kigali/presentation/screens/complete_profile/complete_profile_screen.dart';
import 'package:imuka_kigali/presentation/screens/login/auth_bloc.dart';

import '../helpers/recording_auth_repository.dart';

void main() {
  late RecordingAuthRepository repo;

  setUp(() => repo = RecordingAuthRepository());

  Future<void> showScreen(WidgetTester tester) async {
    // Made inside the test, not in setUp(): widget tests run on a fake
    // clock, and a bloc made outside it never gets to work.
    final bloc = AuthBloc(repo);
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const CompleteProfileScreen(),
        ),
      ),
    );
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    // The test screen is small, so scroll the button into view first.
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets('an empty form shows an error on every field', (tester) async {
    await showScreen(tester);
    await tapText(tester, 'Continue');

    expect(find.text('Choose how you use Imuka'), findsOneWidget);
    expect(find.text('Full name is required'), findsOneWidget);
    expect(find.text('Phone number is required'), findsOneWidget);
    expect(find.text('Choose your district'), findsOneWidget);
  });

  testWidgets('choosing a role clears its error', (tester) async {
    await showScreen(tester);
    await tapText(tester, 'Continue');
    await tapText(tester, 'Drive');
    await tapText(tester, 'Continue');

    expect(find.text('Choose how you use Imuka'), findsNothing);
  });

  testWidgets('a filled form saves the profile with the full phone', (
    tester,
  ) async {
    await showScreen(tester);
    await tapText(tester, 'Move house');
    await tester.enterText(find.byType(TextFormField).at(0), 'Diane Uwase');
    await tester.enterText(find.byType(TextFormField).at(1), '0788 123 456');
    await tapText(tester, 'Kicukiro');
    await tapText(tester, 'Continue');

    final saved = repo.completedProfiles.single;
    expect(saved.role, UserRoles.client);
    expect(saved.fullName, 'Diane Uwase');
    expect(saved.phone, '+250788123456');
    expect(saved.district, 'Kicukiro');
  });

  testWidgets('"Use a different account" signs out', (tester) async {
    await showScreen(tester);
    await tapText(tester, 'Use a different account');

    expect(repo.signOutCalls, 1);
  });
}
