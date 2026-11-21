import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';
import 'package:imuka_kigali/core/theme/app_theme.dart';
import 'package:imuka_kigali/presentation/screens/driver_home/no_vehicle_view.dart';

void main() {
  testWidgets('Register vehicle opens the driver profile on top', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.driverHome,
      routes: [
        GoRoute(
          path: AppRoutes.driverHome,
          builder: (_, _) => const Scaffold(body: NoVehicleView()),
        ),
        GoRoute(
          path: AppRoutes.driverProfile,
          builder: (_, _) => const Scaffold(body: Text('Profile page')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.tap(find.text('Register vehicle'));
    await tester.pumpAndSettle();

    expect(find.text('Profile page'), findsOneWidget);
    expect(router.canPop(), isTrue);
  });
}
