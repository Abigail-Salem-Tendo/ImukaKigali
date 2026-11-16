part of 'finding_driver_bloc.dart';

enum FindingDriverStatus { loading, searching, accepted, cancelled, failure }

class FindingDriverState extends Equatable {
  const FindingDriverState({
    this.status = FindingDriverStatus.loading,
    this.request,
    this.cancelling = false,
    this.error,
  });

  final FindingDriverStatus status;
  final MoveRequest? request;
  final bool cancelling;
  final String? error;

  FindingDriverState copyWith({
    FindingDriverStatus? status,
    MoveRequest? request,
    bool? cancelling,
    String? error,
  }) => FindingDriverState(
    status: status ?? this.status,
    request: request ?? this.request,
    cancelling: cancelling ?? this.cancelling,
    error: error,
  );

  @override
  List<Object?> get props => [status, request, cancelling, error];
}
