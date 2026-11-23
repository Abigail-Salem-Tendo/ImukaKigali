// Owner: Member 1
// Bloc: ClientHomeBloc. Keeps the signed-in client's moves up to date, so
// the home screen shows a new request or a status change by itself.
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/move_request.dart';
import '../../../domain/repositories/request_repository.dart';

part 'client_home_event.dart';
part 'client_home_state.dart';

class ClientHomeBloc extends Bloc<ClientHomeEvent, ClientHomeState> {
  ClientHomeBloc(this._requests) : super(const ClientHomeState()) {
    on<ClientHomeStarted>(_onStarted);
  }

  final RequestRepository _requests;

  Future<void> _onStarted(
    ClientHomeStarted event,
    Emitter<ClientHomeState> emit,
  ) async {
    emit(const ClientHomeState(status: ClientHomeStatus.loading));
    // Stays subscribed for as long as the screen is open.
    await emit.forEach<List<MoveRequest>>(
      _requests.watchMyRequests(event.clientId),
      onData: (moves) =>
          ClientHomeState(status: ClientHomeStatus.success, moves: moves),
      onError: (error, _) => ClientHomeState(
        status: ClientHomeStatus.failure,
        error: error.toString().replaceFirst('Exception: ', ''),
      ),
    );
  }
}
