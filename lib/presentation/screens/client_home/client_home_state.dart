// Owner: Member 1
part of 'client_home_bloc.dart';

enum ClientHomeStatus { loading, success, failure }

class ClientHomeState extends Equatable {
  const ClientHomeState({
    this.status = ClientHomeStatus.loading,
    this.moves = const [],
    this.error,
  });

  final ClientHomeStatus status;

  /// The client's requests, newest first.
  final List<MoveRequest> moves;
  final String? error;

  @override
  List<Object?> get props => [status, moves, error];
}
