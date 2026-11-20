import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';
import 'package:imuka_kigali/core/theme/app_theme.dart';
import 'package:imuka_kigali/presentation/screens/driver_partner_registration/driver_partner_registration_screen.dart';

void main() {
  // The buttons navigate, so the screen needs a real router. The pages it
  // goes to are replaced by plain text we can look for.
  Future<void> showScreen(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.driverPartner,
      routes: [
        GoRoute(
          path: AppRoutes.driverPartner,
          builder: (_, _) => const DriverPartnerRegistrationScreen(),
        ),
        GoRoute(
          path: AppRoutes.driverRegister1,
          builder: (_, _) => const Text('Step 1 page'),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (_, _) => const Text('Login page'),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets('lists what a driver needs', (tester) async {
    await showScreen(tester);

    expect(find.text('Drive & Earn with Imuka'), findsOneWidget);
    expect(find.text('What you need'), findsOneWidget);
    expect(find.textContaining('MoMo phone number'), findsOneWidget);
  });

  testWidgets('Start registration opens driver registration step 1', (
    tester,
  ) async {
    await showScreen(tester);
    await tapText(tester, 'Start registration');

    expect(find.text('Step 1 page'), findsOneWidget);
  });

  testWidgets('Log In goes back to the login page', (tester) async {
    await showScreen(tester);
    await tapText(tester, 'Log In');

    expect(find.text('Login page'), findsOneWidget);
  });
}
