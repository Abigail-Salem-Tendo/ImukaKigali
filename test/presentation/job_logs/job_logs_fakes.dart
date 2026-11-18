import 'dart:async';

import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/core/constants/pricing.dart';
import 'package:imuka_kigali/domain/entities/app_user.dart';
import 'package:imuka_kigali/domain/entities/move_request.dart';
import 'package:imuka_kigali/domain/repositories/auth_repository.dart';
import 'package:imuka_kigali/domain/repositories/driver_job_repository.dart';

const driverId = 'driver1';

MoveRequest testJob({
  required String id,
  String clientId = 'client1',
  String status = RequestStatus.completed,
  double amount = 10000,
  DateTime? createdAt,
}) {
  return MoveRequest(
    id: id,
    clientId: clientId,
    driverId: driverId,
    pickupLocation: 'Kimihurura',
    dropoffLocation: 'Remera',
    itemDescription: 'Fridge and bed',
    vehicleType: VehicleTypes.pickup,
    estimatedMinutes: 30,
    proposedAmount: amount,
    status: status,
    clientConfirmed: false,
    driverConfirmed: false,
    createdAt: createdAt ?? DateTime.now(),
  );
}

AppUser testUser(
  String uid,
  String fullName, {
  String role = UserRoles.client,
}) {
  return AppUser(
    uid: uid,
    role: role,
    fullName: fullName,
    phone: '0788000000',
    email: '$uid@example.com',
    district: 'Gasabo',
    createdAt: DateTime(2026),
  );
}

/// The test pushes job lists into [myJobs] to act like Firestore updates.
class FakeDriverJobRepository implements DriverJobRepository {
  final myJobs = StreamController<List<MoveRequest>>();
  String? watchedDriverId;

  @override
  Stream<List<MoveRequest>> watchMyJobs(String driverId) {
    watchedDriverId = driverId;
    return myJobs.stream;
  }

  @override
  Stream<List<MoveRequest>> watchOpenJobs(String vehicleType) =>
      const Stream.empty();

  @override
  Future<void> acceptJob(String requestId) async {}
}

class FakeAuthRepository implements AuthRepository {
  AppUser? signedIn;
  final Map<String, AppUser> users = {};
  final Set<String> failingUserIds = {};
  final List<String> getUserCalls = [];

  @override
  Future<AppUser?> getCurrentUser() async => signedIn;

  @override
  Future<AppUser?> getUser(String uid) async {
    getUserCalls.add(uid);
    if (failingUserIds.contains(uid)) throw Exception('No permission');
    return users[uid];
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
    required String district,
  }) => throw UnimplementedError();

  @override
  Future<void> sendPasswordReset(String email) => throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();

  @override
  Future<void> updateUser(AppUser user) => throw UnimplementedError();
}
