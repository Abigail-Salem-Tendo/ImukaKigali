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
    this.emailVerified = false,
    this.isLoading = false,
    this.error,
    this.message,
  });

  final AuthStatus status;

  /// The signed-in user's profile. null when signed out.
  final AppUser? user;

  /// Whether the signed-in user has clicked the link in the verification
  /// email. It lives here, not in AppUser, because Firebase Auth keeps it,
  /// not the 'users' document.
  final bool emailVerified;

  /// true while a login, register or reset request is running
  /// (use it for AppButton.isLoading).
  final bool isLoading;

  /// A readable error to show in a snackbar. Cleared on the next state.
  final String? error;

  /// A readable success message. Cleared on the next state.
  final String? message;

  bool get isClient => user?.role == UserRoles.client;
  bool get isDriver => user?.role == UserRoles.driver;

  /// [error] and [message] are not carried over, so each one is shown once.
  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool? emailVerified,
    bool? isLoading,
    String? error,
    String? message,
  }) => AuthState(
    status: status ?? this.status,
    user: user ?? this.user,
    emailVerified: emailVerified ?? this.emailVerified,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    message: message,
  );

  @override
  List<Object?> get props => [
    status,
    user,
    emailVerified,
    isLoading,
    error,
    message,
  ];
}
