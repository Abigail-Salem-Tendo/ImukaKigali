// Owner: Member 3
// RequestRepositoryImpl implements RequestRepository using the 'requests' collection (acceptBid = one batched write).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/domain/entities/move_request.dart';
import 'package:imuka_kigali/domain/repositories/request_repository.dart';

class RequestRepositoryImpl implements RequestRepository {
  RequestRepositoryImpl({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection(Collections.requests);

  @override
  Future<String> createRequest(MoveRequest request) async {
    try {
      final ref = await _requests.add(request.toMap());
      return ref.id;
    } on FirebaseException catch (e) {
      throw Exception(e.message ?? 'Could not create the request');
    }
  }

  @override
  Stream<MoveRequest?> watchRequest(String requestId) =>
      _requests.doc(requestId).snapshots().map((doc) {
        final data = doc.data();
        return data == null ? null : MoveRequest.fromMap(doc.id, data);
      });

  @override
  Stream<List<MoveRequest>> watchMyRequests(String clientId) => _requests
      .where(Fields.clientId, isEqualTo: clientId)
      .orderBy(Fields.createdAt, descending: true)
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((doc) => MoveRequest.fromMap(doc.id, doc.data()))
            .toList(),
      );

  @override
  Future<MoveRequest?> getRequest(String requestId) async {
    try {
      final doc = await _requests.doc(requestId).get();
      final data = doc.data();
      return data == null ? null : MoveRequest.fromMap(doc.id, data);
    } on FirebaseException catch (e) {
      throw Exception(e.message ?? 'Could not load the request');
    }
  }

  @override
  Future<void> updateRequest(
    String requestId,
    Map<String, dynamic> fields,
  ) async {
    try {
      await _requests.doc(requestId).update(fields);
    } on FirebaseException catch (e) {
      throw Exception(e.message ?? 'Could not update the request');
    }
  }

  // A transaction, so a request that a driver accepted a moment ago
  // cannot be cancelled by mistake.
  @override
  Future<void> cancelRequest(String requestId) async {
    final ref = _requests.doc(requestId);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (snap.get(Fields.status) != RequestStatus.open) {
          throw Exception('This request can no longer be cancelled');
        }
        tx.update(ref, {Fields.status: RequestStatus.cancelled});
      });
    } on FirebaseException catch (e) {
      throw Exception(e.message ?? 'Could not cancel the request');
    }
  }
}
