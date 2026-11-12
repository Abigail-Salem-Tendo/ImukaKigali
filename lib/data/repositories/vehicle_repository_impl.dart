

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/firestore_constants.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  // The app calls VehicleRepositoryImpl() with nothing.
  // A test can pass in fake Firestore and FirebaseAuth objects instead.
  VehicleRepositoryImpl({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  /// A shortcut to the 'vehicles' collection.
  CollectionReference<Map<String, dynamic>> get _vehicles =>
      _db.collection(Collections.vehicles);

  @override
  Future<Vehicle> addVehicle({
    required VehicleType vehicleType,
    required String plateNumber,
    required List<String> operatingHubs,
  }) async {
    final driverId = _auth.currentUser?.uid;
    if (driverId == null) {
      throw Exception('Please log in again before adding a vehicle.');
    }

    // Build the vehicle first (no id yet), then turn it into a Map.
    final data = Vehicle(
      id: '',
      driverId: driverId,
      vehicleType: vehicleType,
      plateNumber: plateNumber,
      capacityKg: vehicleType.capacityKg,
      operatingHubs: operatingHubs,
    ).toMap();

    try {
      // add() lets Firestore choose the document id.
      final doc = await _vehicles.add(data);
      return Vehicle.fromMap(doc.id, data);
    } on FirebaseException catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  @override
  Future<Vehicle?> getVehicle(String driverId) async {
    try {
      final snapshot = await _vehicles
          .where(Fields.driverId, isEqualTo: driverId)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) {
        return null; // This driver has no vehicle yet.
      }
      final doc = snapshot.docs.first;
      return Vehicle.fromMap(doc.id, doc.data());
    } on FirebaseException catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  @override
  Future<void> updateVehicle(Vehicle vehicle) async {
    try {
      await _vehicles.doc(vehicle.id).update(vehicle.toMap());
    } on FirebaseException catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  @override
  Future<void> deleteVehicle(String vehicleId) async {
    try {
      await _vehicles.doc(vehicleId).delete();
    } on FirebaseException catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  /// Turns Firebase's technical errors into sentences a driver understands.
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
