// Owner: Member 4
import 'package:imuka_kigali/domain/entities/move_request.dart';

abstract class DriverJobRepository {
  Stream<List<MoveRequest>> watchOpenJobs(String vehicleType);

  Future<void> acceptJob(String requestId);

  Stream<List<MoveRequest>> watchMyJobs(String driverId);
}
