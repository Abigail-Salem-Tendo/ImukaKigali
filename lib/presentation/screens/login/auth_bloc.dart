// Owner: Member 1
// GLOBAL AuthBloc: who is signed in, plus login, register, reset password and
// logout. Provided once in app.dart, so every screen can read it:
//
//   final user = context.select((AuthBloc b) => b.state.user);
//   context.read<AuthBloc>().add(const LogoutRequested());
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/firestore_constants.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repo) : super(const AuthState()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<PasswordResetRequested>(_onPasswordResetRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<EmailVerificationCheckRequested>(_onVerificationCheckRequested);
    on<VerificationEmailResent>(_onVerificationEmailResent);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<ProfileCompleted>(_onProfileCompleted);
  }

  final AuthRepository _repo;

  /// The state for a user who has just been found or signed in.
  /// Every way of signing in ends here, so none of them forgets to check
  /// whether the email is verified.
  Future<AuthState> _signedIn(AppUser user) async {
    return AuthState(
      status: AuthStatus.authenticated,
      user: user,
      emailVerified: await _repo.isEmailVerified(),
    );
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await _repo.getCurrentUser();
      if (user == null) {
        emit(const AuthState(status: AuthStatus.unauthenticated));
      } else {
        emit(await _signedIn(user));
      }
    } catch (e) {
      emit(AuthState(status: AuthStatus.unauthenticated, error: _readable(e)));
    }
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final user = await _repo.signIn(
        email: event.email,
        password: event.password,
      );
      emit(await _signedIn(user));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: _readable(e)));
    }
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final user = await _repo.register(
        fullName: event.fullName,
        email: event.email,
        phone: event.phone,
        password: event.password,
        role: event.role,
        district: event.district,
      );
      emit(await _signedIn(user));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: _readable(e)));
    }
  }

  Future<void> _onPasswordResetRequested(
    PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _repo.sendPasswordReset(event.email);
      emit(
        state.copyWith(
          isLoading: false,
          message: 'We sent a reset link to ${event.email.trim()}.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: _readable(e)));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _repo.signOut();
    } finally {
      // Clear the user even if sign-out failed, so no one else's data shows.
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onVerificationCheckRequested(
    EmailVerificationCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final verified = await _repo.isEmailVerified();
      if (verified) {
        emit(state.copyWith(isLoading: false, emailVerified: true));
      } else {
        emit(
          state.copyWith(
            isLoading: false,
            error: 'Not verified yet. Open the link in the email we sent.',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: _readable(e)));
    }
  }

  Future<void> _onVerificationEmailResent(
    VerificationEmailResent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _repo.sendEmailVerification();
      emit(
        state.copyWith(
          isLoading: false,
          message: 'We sent a new link to ${state.user?.email}.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: _readable(e)));
    }
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final user = await _repo.signInWithGoogle();
      if (user == null) {
        // First time with Google: the router sends them to "Complete your
        // profile".
        emit(const AuthState(status: AuthStatus.needsProfile));
      } else {
        emit(await _signedIn(user));
      }
    } on SignInCancelled {
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: _readable(e)));
    }
  }

  Future<void> _onProfileCompleted(
    ProfileCompleted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final user = await _repo.completeProfile(
        fullName: event.fullName,
        phone: event.phone,
        role: event.role,
        district: event.district,
      );
      emit(await _signedIn(user));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: _readable(e)));
    }
  }

  /// Removes the "Exception: " prefix so the user sees a clean sentence.
  String _readable(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
