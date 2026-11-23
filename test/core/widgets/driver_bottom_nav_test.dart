import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';
import 'package:imuka_kigali/core/theme/app_theme.dart';
import 'package:imuka_kigali/core/widgets/widgets.dart';

void main() {
  late GoRouter router;

  GoRoute tabPage(String path, String title, DriverTab tab) {
    return GoRoute(
      path: path,
      builder: (_, _) => Scaffold(
        body: Text(title),
        bottomNavigationBar: DriverBottomNav(current: tab),
      ),
    );
  }

  Future<void> openNav(WidgetTester tester) async {
    router = GoRouter(
      initialLocation: AppRoutes.driverHome,
      routes: [
        tabPage(AppRoutes.driverHome, 'Home page', DriverTab.home),
        tabPage(AppRoutes.driverJobs, 'Jobs page', DriverTab.jobs),
        tabPage(AppRoutes.jobLogs, 'Job Logs page', DriverTab.jobLogs),
        GoRoute(
          path: AppRoutes.driverProfile,
          builder: (_, _) =>
              Scaffold(appBar: AppBar(), body: const Text('Profile page')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  String currentPath() => router.routerDelegate.currentConfiguration.uri.path;

  int selectedIndex(WidgetTester tester) {
    return tester
        .widget<NavigationBar>(find.byType(NavigationBar))
        .selectedIndex;
  }

  testWidgets('shows the four driver tabs with Home highlighted', (
    tester,
  ) async {
    await openNav(tester);

    for (final label in ['Home', 'Jobs', 'Job Logs', 'Profile']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(selectedIndex(tester), DriverTab.home.index);
    expect(find.bySemanticsLabel('Driver navigation'), findsOneWidget);
  });

  testWidgets('every tab is at least 48 by 48 dp', (tester) async {
    await openNav(tester);

    for (final destination in tester.widgetList(
      find.byType(NavigationDestination),
    )) {
      final size = tester.getSize(find.byWidget(destination));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('Jobs and Job Logs replace the page and move the highlight', (
    tester,
  ) async {
    await openNav(tester);

    await tester.tap(find.text('Jobs'));
    await tester.pumpAndSettle();
    expect(currentPath(), AppRoutes.driverJobs);
    expect(find.text('Jobs page'), findsOneWidget);
    expect(selectedIndex(tester), DriverTab.jobs.index);
    expect(router.canPop(), isFalse);

    await tester.tap(find.text('Job Logs'));
    await tester.pumpAndSettle();
    expect(currentPath(), AppRoutes.jobLogs);
    expect(selectedIndex(tester), DriverTab.jobLogs.index);
    expect(router.canPop(), isFalse);
  });

  testWidgets('Profile opens on top, so Back returns to the tab', (
    tester,
  ) async {
    await openNav(tester);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profile page'), findsOneWidget);
    expect(router.canPop(), isTrue);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Home page'), findsOneWidget);
  });

  testWidgets('tapping the current tab stays on the page', (tester) async {
    await openNav(tester);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(currentPath(), AppRoutes.driverHome);
    expect(find.text('Home page'), findsOneWidget);
  });
}
