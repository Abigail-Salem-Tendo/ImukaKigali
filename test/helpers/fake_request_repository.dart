import 'dart:async';

import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/domain/entities/move_request.dart';
import 'package:imuka_kigali/domain/repositories/request_repository.dart';

/// A request in the accepted state, the way the deal screens see it.
MoveRequest dealRequest({
  String id = 'r1',
  String clientId = 'client1',
  String driverId = 'driver1',
  String status = RequestStatus.accepted,
  bool clientConfirmed = false,
  bool driverConfirmed = false,
}) => MoveRequest(
  id: id,
  clientId: clientId,
  driverId: driverId,
  pickupLocation: 'Kimironko',
  dropoffLocation: 'Nyamirambo',
  itemDescription: 'Sofa',
  vehicleType: 'pickup',
  estimatedMinutes: 40,
  proposedAmount: 12500,
  status: status,
  clientConfirmed: clientConfirmed,
  driverConfirmed: driverConfirmed,
  createdAt: DateTime(2026),
);

/// In-memory RequestRepository. Updating a request pushes the new version to
/// the live stream, like Firestore does.
class FakeRequestRepository implements RequestRepository {
  FakeRequestRepository(this.current);

  MoveRequest? current;
  String? failUpdateWith;
  String? failGetWith;
  final _listeners = <StreamController<MoveRequest?>>[];
  final updates = <Map<String, dynamic>>[];

  /// Pushes [request] to every screen that is watching, like a Firestore change.
  void emit(MoveRequest? request) {
    current = request;
    for (final listener in _listeners) {
      listener.add(request);
    }
  }

  // Like Firestore's snapshots(): the current request first, then every change.
  @override
  Stream<MoveRequest?> watchRequest(String requestId) {
    late final StreamController<MoveRequest?> controller;
    controller = StreamController<MoveRequest?>(
      onListen: () {
        _listeners.add(controller);
        controller.add(current);
      },
      onCancel: () => _listeners.remove(controller),
    );
    return controller.stream;
  }

  @override
  Future<MoveRequest?> getRequest(String requestId) async {
    if (failGetWith != null) throw Exception(failGetWith);
    return current;
  }

  @override
  Future<void> updateRequest(
    String requestId,
    Map<String, dynamic> fields,
  ) async {
    if (failUpdateWith != null) throw Exception(failUpdateWith);
    updates.add(fields);
    final old = current!;
    emit(
      MoveRequest(
        id: old.id,
        clientId: old.clientId,
        driverId: old.driverId,
        pickupLocation: old.pickupLocation,
        dropoffLocation: old.dropoffLocation,
        itemDescription: old.itemDescription,
        vehicleType: old.vehicleType,
        estimatedMinutes: old.estimatedMinutes,
        proposedAmount: old.proposedAmount,
        status: fields[Fields.status] as String? ?? old.status,
        clientConfirmed:
            fields[Fields.clientConfirmed] as bool? ?? old.clientConfirmed,
        driverConfirmed:
            fields[Fields.driverConfirmed] as bool? ?? old.driverConfirmed,
        createdAt: old.createdAt,
      ),
    );
  }

  @override
  Future<String> createRequest(MoveRequest request) =>
      throw UnimplementedError();

  @override
  Stream<List<MoveRequest>> watchMyRequests(String clientId) =>
      throw UnimplementedError();

  @override
  Future<void> cancelRequest(String requestId) => throw UnimplementedError();
}
