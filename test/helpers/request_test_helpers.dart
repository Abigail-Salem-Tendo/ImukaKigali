import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/core/constants/pricing.dart';
import 'package:imuka_kigali/domain/entities/move_request.dart';
import 'package:imuka_kigali/domain/repositories/request_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockRequestRepository extends Mock implements RequestRepository {}

/// Needed by mocktail so `any()` can stand in for a MoveRequest.
class FakeMoveRequest extends Fake implements MoveRequest {}

MoveRequest buildRequest({
  String id = 'r1',
  String clientId = 'c1',
  String driverId = '',
  String status = RequestStatus.open,
}) {
  return MoveRequest(
    id: id,
    clientId: clientId,
    driverId: driverId,
    pickupLocation: 'City Centre',
    dropoffLocation: 'Remera',
    itemDescription: 'A sofa',
    vehicleType: VehicleTypes.pickup,
    estimatedMinutes: 38,
    proposedAmount: 5300,
    status: status,
    clientConfirmed: false,
    driverConfirmed: false,
    createdAt: DateTime(2026),
  );
}
