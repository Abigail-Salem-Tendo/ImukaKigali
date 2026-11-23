part of 'finding_driver_bloc.dart';

sealed class FindingDriverEvent extends Equatable {
  const FindingDriverEvent();

  @override
  List<Object?> get props => [];
}

/// Starts listening to the request document.
class FindingDriverStarted extends FindingDriverEvent {
  const FindingDriverStarted();
}

class CancelRequested extends FindingDriverEvent {
  const CancelRequested();
}
