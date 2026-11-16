/// setup routes  one route per screen; clients and drivers land on different home screens
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';
import 'package:imuka_kigali/presentation/screens/driver_profile/driver_profile_screen.dart';
import 'package:imuka_kigali/presentation/screens/driver_registration_step1/driver_registration_bloc.dart';
import 'package:imuka_kigali/presentation/screens/driver_registration_step1/driver_registration_step1_screen.dart';
import 'package:imuka_kigali/presentation/screens/driver_registration_step2/driver_registration_step2_screen.dart';

/// All routes. Each member replaces the placeholder of their own screens with
/// the real screen (change only your own lines to avoid merge conflicts).
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  routes: [
    _placeholder(AppRoutes.login, 'Login'),
    _placeholder(AppRoutes.createAccount, 'Create account'),
    _placeholder(AppRoutes.driverPartner, 'Driver partner registration'),
    GoRoute(
      path: AppRoutes.driverRegister1,
      builder: (context, state) => const DriverRegistrationStep1Screen(),
    ),
    GoRoute(path: AppRoutes.driverRegister2, builder: _buildDriverRegister2),
    GoRoute(
      path: AppRoutes.driverProfile,
      builder: (context, state) => const DriverProfileScreen(),
    ),
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

/// Builds registration step 2 with the bloc that step 1 passed in "extra".
/// If step 2 is opened without that bloc, step 1 is shown so the driver
/// starts the registration from the beginning.
Widget _buildDriverRegister2(BuildContext context, GoRouterState state) {
  final bloc = state.extra;
  if (bloc is DriverRegistrationBloc) {
    return DriverRegistrationStep2Screen(bloc: bloc);
  }
  return const DriverRegistrationStep1Screen();
}

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
