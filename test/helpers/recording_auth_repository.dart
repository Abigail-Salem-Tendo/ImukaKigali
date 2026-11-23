import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/domain/entities/app_user.dart';
import 'package:imuka_kigali/domain/repositories/auth_repository.dart';

/// Stands in for Firebase in screen tests. It writes down what a screen
/// asked for, so a test can check it. Set [failWith] to make the next
/// sign-in or sign-up fail with that message.
class RecordingAuthRepository implements AuthRepository {
  final List<String> signInEmails = [];
  final List<String> resetEmails = [];
  final List<AppUser> registeredUsers = [];
  int verificationEmailsSent = 0;
  int signOutCalls = 0;
  String? failWith;

  /// The user found when the app starts. null = nobody signed in.
  AppUser? signedIn;

  /// What isEmailVerified() answers.
  bool verified = false;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    signInEmails.add(email);
    if (failWith != null) throw Exception(failWith);
    return AppUser(
      uid: 'u1',
      role: UserRoles.client,
      fullName: 'Diane Uwase',
      phone: '+250781234567',
      email: email,
      district: 'Kicukiro',
      createdAt: DateTime(2026),
    );
  }

  @override
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
    required String district,
  }) async {
    if (failWith != null) throw Exception(failWith);
    final user = AppUser(
      uid: 'new',
      role: role,
      fullName: fullName,
      phone: phone,
      email: email,
      district: district,
      createdAt: DateTime(2026),
    );
    registeredUsers.add(user);
    return user;
  }

  @override
  Future<void> sendPasswordReset(String email) async => resetEmails.add(email);

  @override
  Future<void> sendEmailVerification() async => verificationEmailsSent++;

  @override
  Future<bool> isEmailVerified() async => verified;

  @override
  Future<AppUser?> getCurrentUser() async => signedIn;

  @override
  Future<void> signOut() async {
    signOutCalls++;
    signedIn = null;
  }

  @override
  Future<AppUser?> getUser(String uid) async => null;

  @override
  Future<void> updateUser(AppUser user) async {}
}
