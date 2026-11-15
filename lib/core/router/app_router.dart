// setup routes  one route per screen; clients and drivers land on different home screens
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';

/// All routes. Each member replaces the placeholder of their own screens with
/// the real screen (change only your own lines to avoid merge conflicts).
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  routes: [
    _placeholder(AppRoutes.login, 'Login'),
    _placeholder(AppRoutes.createAccount, 'Create account'),
    _placeholder(AppRoutes.driverPartner, 'Driver partner registration'),
    _placeholder(AppRoutes.driverRegister1, 'Driver registration: step 1'),
    _placeholder(AppRoutes.driverRegister2, 'Driver registration: step 2'),
    _placeholder(AppRoutes.driverProfile, 'Driver profile'),
    _placeholder(AppRoutes.settings, 'Settings'),
    _placeholder(AppRoutes.whereFromTo, 'Where from, where to'),
    _placeholder(AppRoutes.itemDetails, 'Item details'),
    _placeholder(AppRoutes.findingDriver, 'Finding your driver'),
    _placeholder(AppRoutes.driverHome, 'Driver home'),
    _placeholder(AppRoutes.driverJobs, 'Driver jobs'),
    _placeholder(AppRoutes.jobLogs, 'Job logs'),
    _placeholder(AppRoutes.driverContact, 'Driver contact'),
    _placeholder(AppRoutes.delivery, 'Delivery and payment'),
    _placeholder(AppRoutes.rate, 'Rate driver'),
  ],
);

GoRoute _placeholder(String path, String title) {
  return GoRoute(
    path: path,
    builder: (context, state) => _PlaceholderScreen(title: title),
  );
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
