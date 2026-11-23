// setup routes  one route per screen; clients and drivers land on different home screens
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';
import 'package:imuka_kigali/domain/repositories/request_repository.dart';
import 'package:imuka_kigali/presentation/screens/finding_driver/finding_driver_screen.dart';
import 'package:imuka_kigali/presentation/screens/item_details/item_details_screen.dart';
import 'package:imuka_kigali/presentation/screens/where_from_to/create_request_bloc.dart';
import 'package:imuka_kigali/presentation/screens/where_from_to/where_from_to_screen.dart';
import 'package:imuka_kigali/core/router/auth_redirect.dart';
import 'package:imuka_kigali/presentation/screens/client_home/client_home_screen.dart';
import 'package:imuka_kigali/presentation/screens/complete_profile/complete_profile_screen.dart';
import 'package:imuka_kigali/presentation/screens/create_account/create_account_screen.dart';
import 'package:imuka_kigali/presentation/screens/driver_home/driver_home_screen.dart';
import 'package:imuka_kigali/presentation/screens/driver_jobs/driver_jobs_screen.dart';
import 'package:imuka_kigali/presentation/screens/driver_partner_registration/driver_partner_registration_screen.dart';
import 'package:imuka_kigali/presentation/screens/driver_profile/driver_profile_screen.dart';
import 'package:imuka_kigali/presentation/screens/driver_registration_step1/driver_registration_bloc.dart';
import 'package:imuka_kigali/presentation/screens/driver_registration_step1/driver_registration_step1_screen.dart';
import 'package:imuka_kigali/presentation/screens/driver_registration_step2/driver_registration_step2_screen.dart';
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
    GoRoute(
      path: AppRoutes.completeProfile,
      builder: (_, _) => const CompleteProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.driverRegister1,
      builder: (context, state) => const DriverRegistrationStep1Screen(),
    ),
    GoRoute(path: AppRoutes.driverRegister2, builder: _buildDriverRegister2),
    GoRoute(
      path: AppRoutes.driverProfile,
      builder: (context, state) => const DriverProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (_, _) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.clientHome,
      builder: (_, _) => const ClientHomeScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => BlocProvider(
        create: (context) =>
            CreateRequestBloc(context.read<RequestRepository>()),
        child: child,
      ),
      routes: [
        GoRoute(
          path: AppRoutes.whereFromTo,
          builder: (context, state) => const WhereFromToScreen(),
        ),
        GoRoute(
          path: AppRoutes.itemDetails,
          builder: (context, state) => const ItemDetailsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.findingDriver,
      builder: (context, state) =>
          FindingDriverScreen(requestId: state.pathParameters['requestId']!),
    ),
    GoRoute(
      path: AppRoutes.driverHome,
      builder: (_, _) => const DriverHomeScreen(),
    ),
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
