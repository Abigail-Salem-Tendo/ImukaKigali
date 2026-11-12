
// The "what" for vehicles: the list of things the app can do with them.
// The "how" (Firestore) is in data/repositories/vehicle_repository_impl.dart.

import '../entities/vehicle.dart';

abstract class VehicleRepository {
  /// CREATE: saves a new vehicle for the driver who is signed in right now,
  /// and returns it with its new Firestore id.
  Future<Vehicle> addVehicle({
    required VehicleType vehicleType,
    required String plateNumber,
    required List<String> operatingHubs,
  });

  /// READ: the vehicle that belongs to [driverId], or null if they have none.
  /// Teammates can use this too, e.g. to show a bidding driver's vehicle.
  Future<Vehicle?> getVehicle(String driverId);

  /// UPDATE: saves the changed vehicle over the old one.
  Future<void> updateVehicle(Vehicle vehicle);

  /// DELETE: removes the vehicle document.
  Future<void> deleteVehicle(String vehicleId);
}
