import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/core/router/auth_redirect.dart';
import 'package:imuka_kigali/domain/entities/app_user.dart';
import 'package:imuka_kigali/presentation/screens/login/auth_bloc.dart';

AuthState _signedInAs(String role, {bool emailVerified = true}) => AuthState(
  status: AuthStatus.authenticated,
  emailVerified: emailVerified,
  user: AppUser(
    uid: 'u1',
    role: role,
    fullName: 'Diane Uwase',
    phone: '0781234567',
    email: 'diane@example.com',
    district: 'Kicukiro',
    createdAt: DateTime(2026),
  ),
);

const _signedOut = AuthState(status: AuthStatus.unauthenticated);

void main() {
  test('waits while the saved session is still being checked', () {
    expect(authRedirect(const AuthState(), AppRoutes.driverJobs), isNull);
  });

  group('signed out', () {
    test('can stay on login, sign-up and driver registration pages', () {
      expect(authRedirect(_signedOut, AppRoutes.login), isNull);
      expect(authRedirect(_signedOut, AppRoutes.createAccount), isNull);
      expect(authRedirect(_signedOut, AppRoutes.driverPartner), isNull);
      expect(authRedirect(_signedOut, AppRoutes.driverRegister2), isNull);
    });

    test('is sent to login from any other page', () {
      expect(authRedirect(_signedOut, AppRoutes.whereFromTo), AppRoutes.login);
      expect(authRedirect(_signedOut, AppRoutes.jobLogs), AppRoutes.login);
    });
  });

  group('signed in', () {
    test('a client on the login page goes to where-from-to', () {
      expect(
        authRedirect(_signedInAs(UserRoles.client), AppRoutes.login),
        AppRoutes.whereFromTo,
      );
    });

    test('a driver on the login page goes to driver home', () {
      expect(
        authRedirect(_signedInAs(UserRoles.driver), AppRoutes.login),
        AppRoutes.driverHome,
      );
    });

    test('can open any other page', () {
      final driver = _signedInAs(UserRoles.driver);
      expect(authRedirect(driver, AppRoutes.jobLogs), isNull);
      expect(authRedirect(driver, AppRoutes.driverRegister2), isNull);
    });

    test('leaves the inbox page once the email is verified', () {
      expect(
        authRedirect(_signedInAs(UserRoles.client), AppRoutes.verifyEmail),
        AppRoutes.whereFromTo,
      );
    });
  });

  group('signed in but email not verified', () {
    final unverified = _signedInAs(UserRoles.client, emailVerified: false);

    test('is sent to the inbox page from anywhere', () {
      expect(authRedirect(unverified, AppRoutes.login), AppRoutes.verifyEmail);
      expect(
        authRedirect(unverified, AppRoutes.whereFromTo),
        AppRoutes.verifyEmail,
      );
    });

    test('can stay on the inbox page', () {
      expect(authRedirect(unverified, AppRoutes.verifyEmail), isNull);
    });
  });

  test('a signed-out user on the inbox page is sent to login', () {
    expect(authRedirect(_signedOut, AppRoutes.verifyEmail), AppRoutes.login);
  });
}
