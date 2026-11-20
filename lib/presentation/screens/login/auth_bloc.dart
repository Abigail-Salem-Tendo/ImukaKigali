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
  }

  final AuthRepository _repo;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await _repo.getCurrentUser();
      emit(
        user == null
            ? const AuthState(status: AuthStatus.unauthenticated)
            : AuthState(status: AuthStatus.authenticated, user: user),
      );
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
      emit(AuthState(status: AuthStatus.authenticated, user: user));
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
      emit(AuthState(status: AuthStatus.authenticated, user: user));
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

  /// Removes the "Exception: " prefix so the user sees a clean sentence.
  String _readable(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
