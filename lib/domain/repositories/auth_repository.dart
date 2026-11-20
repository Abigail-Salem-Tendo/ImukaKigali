// Owner: Member 1
// What the app can ask about sign-in and the 'users' collection.
// No Firebase here: screens and blocs depend on this, not on the Firebase code.
import '../entities/app_user.dart';

abstract class AuthRepository {
  /// The signed-in user's profile, or null when nobody is signed in.
  /// Waits for Firebase to restore a saved session first, so it is safe to
  /// call when the app starts (this is what keeps users logged in).
  Future<AppUser?> getCurrentUser();

  /// Signs in with email and password and returns the user's profile.
  /// Throws an Exception with a readable message on failure.
  Future<AppUser> signIn({required String email, required String password});

  /// Creates the login account and the user's 'users' document, leaves
  /// them siGned in, and emails them a link to verify their address.
  /// [role] is UserRoles.client or UserRoles.driver.
  /// Throws an Exception with a readble message on failure.
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
    required String district,
  });

  /// Emails a reset-password link.
  Future<void> sendPasswordReset(String email);

  /// Emails the signed-in user a new link to verify their address.
  Future<void> sendEmailVerification();

  /// Whether the signed-in user has clicked the link in that email.
  /// Asks Firebase again each time, so it notices a link clicked just now.
  /// Offline, it answers with the last known status instead of failing.
  Future<bool> isEmailVerified();

  Future<void> signOut();

  /// Reads one user's profile.
  /// Returns null if there is no such user.
  Future<AppUser?> getUser(String uid);

  /// Saves changes to the signedin user's own profile.
  Future<void> updateUser(AppUser user);
}
