import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/core/theme/app_theme.dart';
import 'package:imuka_kigali/core/utils/validators.dart';
import 'package:imuka_kigali/core/widgets/widgets.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  group('AppButton', () {
    testWidgets('shows its label and calls onPressed', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(AppButton(label: 'Log in', onPressed: () => taps++)),
      );
      await tester.tap(find.text('Log in'));
      expect(taps, 1);
    });

    testWidgets('shows a spinner and ignores taps while loading', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          AppButton(label: 'Log in', onPressed: () => taps++, isLoading: true),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Log in'), findsNothing);
      await tester.tap(find.byType(ElevatedButton));
      expect(taps, 0);
    });
  });

  group('AppTextField', () {
    testWidgets('password eye toggles visibility', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppTextField(label: 'Password', isPassword: true)),
      );
      bool obscured() =>
          tester.widget<TextField>(find.byType(TextField)).obscureText;

      expect(obscured(), isTrue);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(obscured(), isFalse);
    });

    testWidgets('shows the validator message when the form is checked', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        _wrap(
          Form(
            key: formKey,
            child: const AppTextField(
              label: 'Email',
              validator: Validators.email,
            ),
          ),
        ),
      );
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Email is required'), findsOneWidget);
    });
  });

  testWidgets('StatusChip.request shows a readable label', (tester) async {
    await tester.pumpWidget(_wrap(StatusChip.request(RequestStatus.completed)));
    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets('EmptyState.error calls onRetry', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      _wrap(EmptyState.error(onRetry: () => retried = true)),
    );
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  testWidgets('LoadingView shows a spinner and message', (tester) async {
    await tester.pumpWidget(_wrap(const LoadingView(message: 'Loading jobs')));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading jobs'), findsOneWidget);
  });

  testWidgets('showAppSnackBar shows the message', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showAppSnackBar(
              context,
              'Could not log in',
              type: SnackBarType.error,
            ),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    expect(find.text('Could not log in'), findsOneWidget);
  });

  testWidgets('BrandHeader shows the app name, and a subtitle when given', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const BrandHeader()));
    expect(find.text('Imuka Kigali'), findsOneWidget);
    expect(find.text('Driver Partner'), findsNothing);

    await tester.pumpWidget(
      _wrap(const BrandHeader(subtitle: 'Driver Partner')),
    );
    expect(find.text('Driver Partner'), findsOneWidget);
  });
}
