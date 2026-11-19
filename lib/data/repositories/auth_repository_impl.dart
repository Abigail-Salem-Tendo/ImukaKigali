// Owner: Member 1
// AuthRepositoryImpl: the Firebase code behind AuthRepository
// (firebase_auth for the login account, the 'users' collection for the profile).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/firestore_constants.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({FirebaseAuth? auth, FirebaseFirestore? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(Collections.users);

  @override
  Future<AppUser?> getCurrentUser() async {
    // The first event is the restored session (orr null), so a returning user
    // is found even if Firebase has not finished loading it yet.
    final firebaseUser = await _auth.authStateChanges().first;
    if (firebaseUser == null) return null;
    return getUser(firebaseUser.uid);
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = await getUser(cred.user!.uid);
      if (user == null) {
        await _auth.signOut();
        throw Exception(
          'We could not find your profile. Please create an account.',
        );
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_readable(e));
    }
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
    final UserCredential cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_readable(e));
    }

    final user = AppUser(
      uid: cred.user!.uid,
      role: role,
      fullName: fullName.trim(),
      phone: phone.trim(),
      email: email.trim(),
      district: district,
      createdAt: DateTime.now(),
    );

    try {
      await _users.doc(user.uid).set({
        ...user.toMap(),
        Fields.createdAt: FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      // Don't leave a login with no profile behind: remove it so the person
      // can simply try again with the same email.
      await cred.user?.delete();
      throw Exception(e.message ?? 'Could not save your profile. Try again.');
    }

    // The account is ready even if this email fails to send, so a failure
    // here is ignored: the "Check your inbox" screen has a Resend button.
    try {
      await cred.user!.sendEmailVerification();
    } on FirebaseAuthException {
      // Ignored on purpose (see above).
    }
    return user;
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw Exception(_readable(e));
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }
    try {
      // Firebase remembers the user as they were at login. reload() fetches
      // them again, so a link clicked a moment ago is seen.
      await user.reload();
    } on FirebaseAuthException catch (e) {
      throw Exception(_readable(e));
    }
    // Read currentUser again: reload() refreshes Firebase's copy, not the
    // old `user` object we are holding.
    return _auth.currentUser?.emailVerified ?? false;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_readable(e));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<AppUser?> getUser(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      return AppUser.fromMap(doc.id, data);
    } on FirebaseException catch (e) {
      throw Exception(e.message ?? 'Could not load the profile.');
    }
  }

  @override
  Future<void> updateUser(AppUser user) async {
    try {
      // createdAt is never changed after registration.
      final data = user.toMap()..remove(Fields.createdAt);
      await _users.doc(user.uid).update(data);
    } on FirebaseException catch (e) {
      throw Exception(e.message ?? 'Could not save your changes.');
    }
  }

  /// Turns Firebase error codes into sentences a user understands.
  String _readable(FirebaseAuthException e) => switch (e.code) {
    'invalid-email' => 'That email address is not valid.',
    'user-disabled' => 'This account has been disabled.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'Incorrect email or password.',
    'email-already-in-use' => 'An account already exists with this email.',
    'weak-password' => 'Choose a stronger password.',
    'too-many-requests' => 'Too many attempts. Please wait and try again.',
    'network-request-failed' =>
      'No internet connection. Check your network and try again.',
    'operation-not-allowed' => 'This sign-in method is not enabled.',
    _ => e.message ?? 'Something went wrong. Please try again.',
  };
}
