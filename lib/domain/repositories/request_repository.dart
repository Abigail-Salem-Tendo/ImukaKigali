// Owner: Member 3
// abstract class RequestRepository: createRequest, watchMyRequests, getRequest, updateRequest, cancelRequest
import 'package:imuka_kigali/domain/entities/move_request.dart';

/// Everything the app can do with the `requests` collection from the client
/// side, plus the shared reads used by drivers and the deal screens.
/// No Firebase here. Drivers accept jobs through DriverJobRepository, not here.
abstract class RequestRepository {
  /// Saves a new request and returns the id Firestore gave it.
  /// The request must already have status `open`, an empty `driverId`,
  /// and the calculated `vehicleType`, `estimatedMinutes`, `proposedAmount`.
  Future<String> createRequest(MoveRequest request);

  /// One request, live. Emits null if the document does not exist.
  /// Also used by finding_driver, driver_contact and delivery.
  Stream<MoveRequest?> watchRequest(String requestId);

  /// All requests of one client, newest first, live.
  Stream<List<MoveRequest>> watchMyRequests(String clientId);

  /// One request, read once. Returns null if it does not exist.
  Future<MoveRequest?> getRequest(String requestId);

  /// Updates only the given fields (for example `Fields.clientConfirmed`).
  Future<void> updateRequest(String requestId, Map<String, dynamic> fields);

  /// Sets status to `cancelled`, but only while the request is still `open`.
  /// Throws an Exception with a readable message otherwise.
  Future<void> cancelRequest(String requestId);
}
