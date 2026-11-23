// Owner: Member 4
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/domain/entities/move_request.dart';
import 'package:imuka_kigali/domain/repositories/driver_job_repository.dart';

class DriverJobRepositoryImpl implements DriverJobRepository {
  DriverJobRepositoryImpl({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection(Collections.requests);

  @override
  Stream<List<MoveRequest>> watchOpenJobs(String vehicleType) {
    final query = _requests
        .where(Fields.status, isEqualTo: RequestStatus.open)
        .where(Fields.vehicleType, isEqualTo: vehicleType)
        .orderBy(Fields.createdAt, descending: true);
    return _watchJobs(query, 'Could not load open jobs');
  }

  @override
  Stream<List<MoveRequest>> watchMyJobs(String driverId) {
    final query = _requests
        .where(Fields.driverId, isEqualTo: driverId)
        .orderBy(Fields.createdAt, descending: true);
    return _watchJobs(query, 'Could not load your jobs');
  }

  // A transaction so two drivers tapping Accept at once cannot both win.
  @override
  Future<void> acceptJob(String requestId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Please sign in again to accept this job');
    }
    final ref = _requests.doc(requestId);
    try {
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        // A deleted request has no status, so it is treated as taken too.
        if (snapshot.data()?[Fields.status] != RequestStatus.open) {
          throw Exception('This job was just taken by another driver');
        }
        transaction.update(ref, {
          Fields.driverId: user.uid,
          Fields.status: RequestStatus.accepted,
        });
      });
    } on FirebaseException catch (e) {
      throw Exception(e.message ?? 'Could not accept the job');
    }
  }

  Stream<List<MoveRequest>> _watchJobs(
    Query<Map<String, dynamic>> query,
    String failureMessage,
  ) {
    return query
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MoveRequest.fromMap(doc.id, doc.data()))
              .toList(),
        )
        .handleError(
          // Keeps Firestore's message, because a missing index error
          // contains the link Member 3 needs to create the index.
          (Object error) => throw Exception(
            (error as FirebaseException).message ?? failureMessage,
          ),
          test: (error) => error is FirebaseException,
        );
  }
}
