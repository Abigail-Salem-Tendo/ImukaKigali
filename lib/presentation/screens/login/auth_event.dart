// Owner: Member 1
part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Checks for a saved session (sent once when the app starts) and reloads
/// the signed-in user's profile (e.g. after driver registration).
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class LoginSubmitted extends AuthEvent {
  const LoginSubmitted({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class RegisterSubmitted extends AuthEvent {
  const RegisterSubmitted({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
    required this.district,
  });

  final String fullName;
  final String email;
  final String phone;
  final String password;

  /// UserRoles.client or UserRoles.driver.
  final String role;
  final String district;

  @override
  List<Object?> get props => [fullName, email, phone, password, role, district];
}

class PasswordResetRequested extends AuthEvent {
  const PasswordResetRequested(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
