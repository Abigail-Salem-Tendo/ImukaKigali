// Owner: Member 1
// Decides where the router should send the user, based on whether they are
// signed in and on their role. Kept apart from app_router.dart and free of
// widgets, so the rules can be unit-tested with a plain AuthState.
import '../../presentation/screens/login/auth_bloc.dart';
import '../constants/app_routes.dart';

/// Pages a signed-out user can open.
const _publicPages = [
  AppRoutes.login,
  AppRoutes.createAccount,
  AppRoutes.driverPartner,
  AppRoutes.driverRegister1,
  AppRoutes.driverRegister2,
];

/// Pages that only make sense before logging in. A signed-in user who
/// lands on one of them is sent to their home screen instead.
///
/// The driver registration steps are not listed on purpose: Liliane's flow
/// creates the account on step 2 and moves the new driver on by itself.
const _signedOutOnlyPages = [
  AppRoutes.login,
  AppRoutes.createAccount,
  AppRoutes.driverPartner,
];

/// Returns the path to go to instead of [location], or null to stay.
String? authRedirect(AuthState auth, String location) {
  // While the saved session is still being checked we don't know yet who
  // the user is, so we wait instead of flashing the wrong screen.
  if (auth.status == AuthStatus.unknown) {
    return null;
  }

  if (auth.status == AuthStatus.unauthenticated) {
    if (_publicPages.contains(location)) {
      return null;
    }
    return AppRoutes.login;
  }

  // From here on the user is signed in.
  if (_signedOutOnlyPages.contains(location)) {
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
