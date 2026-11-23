/// setup routes  one route per screen; clients and drivers land on different home screens
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';
import 'package:imuka_kigali/core/router/auth_redirect.dart';
import 'package:imuka_kigali/presentation/screens/create_account/create_account_screen.dart';
import 'package:imuka_kigali/presentation/screens/driver_jobs/driver_jobs_screen.dart';
import 'package:imuka_kigali/presentation/screens/driver_partner_registration/driver_partner_registration_screen.dart';
import 'package:imuka_kigali/presentation/screens/job_logs/job_logs_screen.dart';
import 'package:imuka_kigali/presentation/screens/login/auth_bloc.dart';
import 'package:imuka_kigali/presentation/screens/login/login_screen.dart';
import 'package:imuka_kigali/presentation/screens/settings/settings_screen.dart';
import 'package:imuka_kigali/presentation/screens/verify_email/verify_email_screen.dart';

/// All routes. Each member replaces the placeholder of their own screens with
/// the real screen (change only your own lines to avoid merge conflicts).
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  // Runs before every navigation, and again when app.dart calls
  // appRouter.refresh() after a login or logout.
  redirect: (context, state) =>
      authRedirect(context.read<AuthBloc>().state, state.matchedLocation),
  routes: [
    GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
    GoRoute(
      path: AppRoutes.createAccount,
      builder: (_, _) => const CreateAccountScreen(),
    ),
    GoRoute(
      path: AppRoutes.driverPartner,
      builder: (_, _) => const DriverPartnerRegistrationScreen(),
    ),
    GoRoute(
      path: AppRoutes.verifyEmail,
      builder: (_, _) => const VerifyEmailScreen(),
    ),
    _placeholder(AppRoutes.driverRegister1, 'Driver registration: step 1'),
    _placeholder(AppRoutes.driverRegister2, 'Driver registration: step 2'),
    _placeholder(AppRoutes.driverProfile, 'Driver profile'),
    GoRoute(
      path: AppRoutes.settings,
      builder: (_, _) => const SettingsScreen(),
    ),
    _placeholder(AppRoutes.whereFromTo, 'Where from, where to'),
    _placeholder(AppRoutes.itemDetails, 'Item details'),
    _placeholder(AppRoutes.findingDriver, 'Finding your driver'),
    _placeholder(AppRoutes.driverHome, 'Driver home'),
    GoRoute(
      path: AppRoutes.driverJobs,
      builder: (_, _) => const DriverJobsScreen(),
    ),
    GoRoute(path: AppRoutes.jobLogs, builder: (_, _) => const JobLogsScreen()),
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
