// Owner: Member 1
// Decides where the router should send the user, based on whether they are
// signed in and on their role. Kept apart from app_router.dart and free of
// widgets, so the rules can be unit-tested with a plain AuthState.
import '../../presentation/screens/login/auth_bloc.dart';
import '../constants/app_routes.dart';

/// The only pages a signed-out user can open. They are also the pages a
/// signed-in user has no reason to see: the registration steps would
/// create a second account.
const _signedOutPages = [
  AppRoutes.login,
  AppRoutes.createAccount,
  AppRoutes.driverPartner,
  AppRoutes.driverRegister1,
  AppRoutes.driverRegister2,
];

/// Pages only drivers use.
const _driverPages = [
  AppRoutes.driverHome,
  AppRoutes.driverJobs,
  AppRoutes.jobLogs,
  AppRoutes.driverProfile,
];

/// Pages only clients use.
bool _isClientPage(String location) {
  // Finding-driver paths end with a request id (/finding-driver/abc123),
  // so they are matched by their start, not compared whole.
  return location == AppRoutes.whereFromTo ||
      location == AppRoutes.itemDetails ||
      location.startsWith(AppRoutes.findingDriverPath(''));
}

/// Returns the path to go to instead of [location], or null to stay.
String? authRedirect(AuthState auth, String location) {
  // While the saved session is still being checked we don't know yet who
  // the user is, so we wait. The login screen shows a spinner meanwhile.
  if (auth.status == AuthStatus.unknown) {
    return null;
  }

  if (auth.status == AuthStatus.unauthenticated) {
    if (_signedOutPages.contains(location)) {
      return null;
    }
    return AppRoutes.login;
  }

  // From here on the user is signed in.

  // Blocked until they click the link in the verification email.
  if (!auth.emailVerified) {
    if (location == AppRoutes.verifyEmail) {
      return null;
    }
    return AppRoutes.verifyEmail;
  }

  // Verified. The inbox page has done its job, so it counts as a page
  // they no longer need, like login.
  if (_signedOutPages.contains(location) || location == AppRoutes.verifyEmail) {
    return homeFor(auth);
  }
  // Each role stays on its own side of the app.
  if (auth.isDriver && _isClientPage(location)) {
    return homeFor(auth);
  }
  if (auth.isClient && _driverPages.contains(location)) {
    return homeFor(auth);
  }
  return null;
}

/// Clients and drivers have different home screens.
String homeFor(AuthState auth) {
  if (auth.isDriver) {
    return AppRoutes.driverHome;
  }
  return AppRoutes.whereFromTo;
}
