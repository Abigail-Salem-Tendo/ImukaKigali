// Owner: Member 2
// abstract class VehicleRepository: addVehicle, getVehicle, updateVehicle, deleteVehicle.
import 'package:imuka_kigali/domain/entities/vehicle.dart';

/// The list of things the app can do with vehicles.
/// The Firestore code behind each method is in
/// data/repositories/vehicle_repository_impl.dart.
abstract class VehicleRepository {
  /// Saves a new vehicle for the driver who is signed in, and returns it
  /// with its new Firestore id.
  Future<Vehicle> addVehicle({
    required String vehicleType,
    required String plateNumber,
  });

  /// Returns the vehicle that belongs to [driverId], or null if that driver
  /// has not registered one.
  Future<Vehicle?> getVehicle(String driverId);

  /// Saves the changed [vehicle] over the one already in Firestore.
  Future<void> updateVehicle(Vehicle vehicle);

  /// Deletes the vehicle document with the id [vehicleId].
  Future<void> deleteVehicle(String vehicleId);
}
