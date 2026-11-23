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

    test('can open the pages of their own role', () {
      expect(
        authRedirect(_signedInAs(UserRoles.driver), AppRoutes.jobLogs),
        isNull,
      );
      expect(
        authRedirect(_signedInAs(UserRoles.client), AppRoutes.itemDetails),
        isNull,
      );
    });

    test('is sent home from the registration steps', () {
      expect(
        authRedirect(_signedInAs(UserRoles.driver), AppRoutes.driverRegister1),
        AppRoutes.driverHome,
      );
    });

    test('a client is sent away from driver pages', () {
      expect(
        authRedirect(_signedInAs(UserRoles.client), AppRoutes.driverHome),
        AppRoutes.whereFromTo,
      );
    });

    test('a driver is sent away from client pages', () {
      final driver = _signedInAs(UserRoles.driver);
      expect(authRedirect(driver, AppRoutes.whereFromTo), AppRoutes.driverHome);
      expect(
        authRedirect(driver, AppRoutes.findingDriverPath('abc123')),
        AppRoutes.driverHome,
      );
    });

    test('both roles can open shared pages', () {
      final path = AppRoutes.deliveryPath('abc123');
      expect(authRedirect(_signedInAs(UserRoles.client), path), isNull);
      expect(authRedirect(_signedInAs(UserRoles.driver), path), isNull);
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

  group('signed in with Google, no profile yet', () {
    const needsProfile = AuthState(status: AuthStatus.needsProfile);

    test('is sent to "Complete your profile" from anywhere', () {
      expect(
        authRedirect(needsProfile, AppRoutes.login),
        AppRoutes.completeProfile,
      );
      expect(
        authRedirect(needsProfile, AppRoutes.driverHome),
        AppRoutes.completeProfile,
      );
    });

    test('can stay on "Complete your profile"', () {
      expect(authRedirect(needsProfile, AppRoutes.completeProfile), isNull);
    });
  });

  test('leaves "Complete your profile" once the profile is saved', () {
    expect(
      authRedirect(_signedInAs(UserRoles.driver), AppRoutes.completeProfile),
      AppRoutes.driverHome,
    );
  });

  test('a signed-out user on "Complete your profile" is sent to login', () {
    expect(
      authRedirect(_signedOut, AppRoutes.completeProfile),
      AppRoutes.login,
    );
  });
}
