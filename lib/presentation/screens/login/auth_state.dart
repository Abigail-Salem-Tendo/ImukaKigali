// Owner: Member 1
part of 'auth_bloc.dart';

enum AuthStatus {
  /// The app has just started and the saved session hasn't been checked yet.
  unknown,
  authenticated,
  unauthenticated,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isLoading = false,
    this.error,
    this.message,
  });

  final AuthStatus status;

  /// The signed-in user's profile. null when signed out.
  final AppUser? user;

  /// true while a login, register or reset request is running
  /// (use it for AppButton.isLoading).
  final bool isLoading;

  /// A readable error to show in a snackbar. Cleared on the next state.
  final String? error;

  /// A readable success message (e.g. "reset link sent"). Cleared on the next state.
  final String? message;

  bool get isClient => user?.role == UserRoles.client;
  bool get isDriver => user?.role == UserRoles.driver;

  /// [error] and [message] are not carried over, so each one is shown once.
  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool? isLoading,
    String? error,
    String? message,
  }) => AuthState(
    status: status ?? this.status,
    user: user ?? this.user,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    message: message,
  );

  @override
  List<Object?> get props => [status, user, isLoading, error, message];
}
