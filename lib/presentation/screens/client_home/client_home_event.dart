// Owner: Member 1
part of 'client_home_bloc.dart';

sealed class ClientHomeEvent extends Equatable {
  const ClientHomeEvent();

  @override
  List<Object?> get props => [];
}

/// The home screen opened (or Retry was tapped): start watching the moves.
class ClientHomeStarted extends ClientHomeEvent {
  const ClientHomeStarted(this.clientId);

  final String clientId;

  @override
  List<Object?> get props => [clientId];
}
