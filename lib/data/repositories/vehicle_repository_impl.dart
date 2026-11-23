// Owner: Member 2
// VehicleRepositoryImpl implements VehicleRepository using the 'vehicles' collection.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/domain/entities/vehicle.dart';
import 'package:imuka_kigali/domain/entities/vehicle_class.dart';
import 'package:imuka_kigali/domain/repositories/vehicle_repository.dart';

/// The Firestore code for vehicles. Only this layer imports Firebase.
class VehicleRepositoryImpl implements VehicleRepository {
  /// Creates the repository. The app passes nothing, so the real Firebase
  /// is used. A test can pass fake [db] and [auth] objects instead.
  VehicleRepositoryImpl({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  /// A shortcut to the 'vehicles' collection.
  CollectionReference<Map<String, dynamic>> get _vehicles =>
      _db.collection(Collections.vehicles);

  /// Creates a vehicle document owned by the signed-in driver.
  /// The capacity is filled in from the chosen vehicle type.
  /// Throws an Exception with a readable message if nobody is signed in
  /// or Firestore refuses the write.
  @override
  Future<Vehicle> addVehicle({
    required String vehicleType,
    required String plateNumber,
  }) async {
    final driverId = _auth.currentUser?.uid;
    if (driverId == null) {
      throw Exception('Please log in again before adding a vehicle.');
    }

    final data = Vehicle(
      id: '',
      driverId: driverId,
      vehicleType: vehicleType,
      plateNumber: plateNumber,
      capacityKg: VehicleClasses.of(vehicleType).capacityKg,
    ).toMap();

    try {
      // add() lets Firestore choose the document id.
      final doc = await _vehicles.add(data);
      return Vehicle.fromMap(doc.id, data);
    } on FirebaseException catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  /// Looks for the one vehicle whose driverId equals [driverId].
  /// Returns null when the driver has no vehicle.
  @override
  Future<Vehicle?> getVehicle(String driverId) async {
    try {
      final snapshot = await _vehicles
          .where(Fields.driverId, isEqualTo: driverId)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) {
        return null;
      }
      final doc = snapshot.docs.first;
      return Vehicle.fromMap(doc.id, doc.data());
    } on FirebaseException catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  /// Writes every field of [vehicle] over the document with the same id.
  @override
  Future<void> updateVehicle(Vehicle vehicle) async {
    try {
      await _vehicles.doc(vehicle.id).update(vehicle.toMap());
    } on FirebaseException catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  /// Removes the vehicle document with the id [vehicleId].
  @override
  Future<void> deleteVehicle(String vehicleId) async {
    try {
      await _vehicles.doc(vehicleId).delete();
    } on FirebaseException catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  /// Turns a Firebase error code into a sentence a driver can understand.
  String _friendlyMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You are not allowed to change this vehicle.';
      case 'unavailable':
        return 'No internet connection. Please try again.';
      case 'not-found':
        return 'This vehicle no longer exists.';
      default:
        return e.message ?? 'Something went wrong with your vehicle.';
    }
  }
}
