import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/domain/entities/app_user.dart';
import 'package:imuka_kigali/domain/repositories/auth_repository.dart';
import 'package:imuka_kigali/presentation/screens/login/auth_bloc.dart';

final _client = AppUser(
  uid: 'u1',
  role: UserRoles.client,
  fullName: 'Diane Uwase',
  phone: '0781234567',
  email: 'diane@example.com',
  district: 'Kicukiro',
  createdAt: DateTime(2026),
);

/// In-memory AuthRepository so the bloc can be tested without Firebase.
class FakeAuthRepository implements AuthRepository {
  AppUser? signedIn;
  String? failWith;
  int signOutCalls = 0;
  String? resetEmail;
  bool verified = false;
  int verificationEmailsSent = 0;

  void _maybeFail() {
    if (failWith != null) throw Exception(failWith);
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    _maybeFail();
    return signedIn;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    _maybeFail();
    return signedIn = _client;
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
    _maybeFail();
    return signedIn = AppUser(
      uid: 'new',
      role: role,
      fullName: fullName,
      phone: phone,
      email: email,
      district: district,
      createdAt: DateTime(2026),
    );
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    _maybeFail();
    resetEmail = email;
  }

  /// What signInWithGoogle() does: return this profile (null = first
  /// time), or throw SignInCancelled when [googleCancelled] is true.
  AppUser? googleProfile;
  bool googleCancelled = false;

  @override
  Future<AppUser?> signInWithGoogle() async {
    _maybeFail();
    if (googleCancelled) throw const SignInCancelled();
    return signedIn = googleProfile;
  }

  @override
  Future<AppUser> completeProfile({
    required String fullName,
    required String phone,
    required String role,
    required String district,
  }) async {
    _maybeFail();
    return signedIn = AppUser(
      uid: 'google-user',
      role: role,
      fullName: fullName,
      phone: phone,
      email: 'diane@gmail.com',
      district: district,
      createdAt: DateTime(2026),
    );
  }

  @override
  Future<void> sendEmailVerification() async {
    _maybeFail();
    verificationEmailsSent++;
  }

  @override
  Future<bool> isEmailVerified() async => verified;

  @override
  Future<void> signOut() async {
    signOutCalls++;
    signedIn = null;
  }

  @override
  Future<AppUser?> getUser(String uid) async => signedIn;

  @override
  Future<void> updateUser(AppUser user) async => signedIn = user;
}

void main() {
  late FakeAuthRepository repo;
  late AuthBloc bloc;

  setUp(() {
    repo = FakeAuthRepository();
    bloc = AuthBloc(repo);
  });
  tearDown(() => bloc.close());

  test('starts with an unknown status', () {
    expect(bloc.state.status, AuthStatus.unknown);
  });

  test('AuthCheckRequested with no saved session → unauthenticated', () async {
    bloc.add(const AuthCheckRequested());
    await expectLater(
      bloc.stream,
      emits(const AuthState(status: AuthStatus.unauthenticated)),
    );
  });

  test('AuthCheckRequested with a saved session → authenticated', () async {
    repo.signedIn = _client;
    bloc.add(const AuthCheckRequested());
    await expectLater(
      bloc.stream,
      emits(AuthState(status: AuthStatus.authenticated, user: _client)),
    );
    expect(bloc.state.isClient, isTrue);
  });

  test('successful login: loading, then authenticated', () async {
    bloc.add(const LoginSubmitted(email: 'diane@example.com', password: 'x'));
    await expectLater(
      bloc.stream,
      emitsInOrder([
        const AuthState(isLoading: true),
        AuthState(status: AuthStatus.authenticated, user: _client),
      ]),
    );
  });

  test('failed login shows a readable error without "Exception:"', () async {
    repo.failWith = 'Incorrect email or password.';
    bloc.add(const LoginSubmitted(email: 'diane@example.com', password: 'x'));
    await expectLater(
      bloc.stream,
      emitsInOrder([
        const AuthState(isLoading: true),
        const AuthState(error: 'Incorrect email or password.'),
      ]),
    );
  });

  test('register a driver → authenticated as a driver', () async {
    bloc.add(
      const RegisterSubmitted(
        fullName: 'Jean-Claude Mugisha',
        email: 'jc@example.com',
        phone: '0788123456',
        password: 'kigali2026',
        role: UserRoles.driver,
        district: 'Gasabo',
      ),
    );
    await bloc.stream.firstWhere((s) => s.status == AuthStatus.authenticated);
    expect(bloc.state.isDriver, isTrue);
    expect(bloc.state.user!.fullName, 'Jean-Claude Mugisha');
  });

  test('password reset sends the email and shows a message', () async {
    bloc.add(const PasswordResetRequested('diane@example.com'));
    final done = await bloc.stream.firstWhere((s) => s.message != null);
    expect(repo.resetEmail, 'diane@example.com');
    expect(done.message, contains('diane@example.com'));
  });

  test('logout signs out and clears the user', () async {
    repo.signedIn = _client;
    bloc.add(const AuthCheckRequested());
    await bloc.stream.firstWhere((s) => s.status == AuthStatus.authenticated);

    bloc.add(const LogoutRequested());
    await expectLater(
      bloc.stream,
      emits(const AuthState(status: AuthStatus.unauthenticated)),
    );
    expect(repo.signOutCalls, 1);
    expect(bloc.state.user, isNull);
  });

  group('email verification', () {
    test('login reads whether the email is verified', () async {
      repo.verified = true;
      bloc.add(const LoginSubmitted(email: 'diane@example.com', password: 'x'));
      final done = await bloc.stream.firstWhere(
        (s) => s.status == AuthStatus.authenticated,
      );
      expect(done.emailVerified, isTrue);
    });

    test('"I\'ve verified" after clicking the link → verified', () async {
      repo.verified = true;
      bloc.add(const EmailVerificationCheckRequested());
      final done = await bloc.stream.firstWhere((s) => !s.isLoading);
      expect(done.emailVerified, isTrue);
      expect(done.error, isNull);
    });

    test('"I\'ve verified" without clicking the link → error', () async {
      bloc.add(const EmailVerificationCheckRequested());
      final done = await bloc.stream.firstWhere((s) => !s.isLoading);
      expect(done.emailVerified, isFalse);
      expect(done.error, contains('Not verified yet'));
    });

    test('resend sends a new email and shows a message', () async {
      repo.signedIn = _client;
      bloc.add(const AuthCheckRequested());
      await bloc.stream.firstWhere((s) => s.status == AuthStatus.authenticated);

      bloc.add(const VerificationEmailResent());
      final done = await bloc.stream.firstWhere((s) => s.message != null);
      expect(repo.verificationEmailsSent, 1);
      expect(done.message, contains('diane@example.com'));
    });
  });

  group('Google sign-in', () {
    test('a first-time Google user must complete their profile', () async {
      bloc.add(const GoogleSignInRequested());
      final done = await bloc.stream.firstWhere((s) => !s.isLoading);
      expect(done.status, AuthStatus.needsProfile);
      expect(done.user, isNull);
    });

    test('a returning Google user is signed in', () async {
      repo
        ..googleProfile = _client
        ..verified = true;
      bloc.add(const GoogleSignInRequested());
      final done = await bloc.stream.firstWhere(
        (s) => s.status == AuthStatus.authenticated,
      );
      expect(done.user, _client);
    });

    test('closing the account picker shows no error', () async {
      repo.googleCancelled = true;
      bloc.add(const GoogleSignInRequested());
      final done = await bloc.stream.firstWhere((s) => !s.isLoading);
      expect(done.error, isNull);
      expect(done.status, AuthStatus.unknown);
    });

    test('a failed Google sign-in shows the error', () async {
      repo.failWith = 'Google sign-in failed. Please try again.';
      bloc.add(const GoogleSignInRequested());
      final done = await bloc.stream.firstWhere((s) => s.error != null);
      expect(done.error, 'Google sign-in failed. Please try again.');
    });
  });

  group('complete profile', () {
    const event = ProfileCompleted(
      fullName: 'Diane Uwase',
      phone: '+250781234567',
      role: UserRoles.driver,
      district: 'Gasabo',
    );

    test('saving the profile signs the user in with that role', () async {
      repo.verified = true;
      bloc.add(event);
      final done = await bloc.stream.firstWhere(
        (s) => s.status == AuthStatus.authenticated,
      );
      expect(done.isDriver, isTrue);
      expect(done.user!.district, 'Gasabo');
      expect(done.emailVerified, isTrue);
    });

    test('a failed save shows the error and stays on the page', () async {
      repo.failWith = 'Could not save your profile. Try again.';
      bloc.add(event);
      final done = await bloc.stream.firstWhere((s) => s.error != null);
      expect(done.error, 'Could not save your profile. Try again.');
      expect(done.status, isNot(AuthStatus.authenticated));
    });
  });
}
