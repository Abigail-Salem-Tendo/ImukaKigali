import 'dart:async';

import 'package:imuka_kigali/domain/entities/vehicle.dart';
import 'package:imuka_kigali/domain/entities/vehicle_class.dart';
import 'package:imuka_kigali/domain/repositories/vehicle_repository.dart';

/// Waits until the bloc has handled every event added so far, including
/// the awaits inside its handlers, before the test checks the state.
Future<void> settle() => Future<void>.delayed(Duration.zero);

/// A VehicleRepository that keeps the vehicle in memory instead of
/// Firestore. It writes down every call so a test can check what the bloc
/// asked for, and each method can be made to fail.
class FakeVehicleRepository implements VehicleRepository {
  /// The id of the driver every new vehicle belongs to.
  static const ownerId = 'driver1';

  /// The vehicle getVehicle returns. Null means the driver has none.
  Vehicle? stored;

  /// When one of these is set, the matching method throws an Exception
  /// with that text, like Firestore does when something goes wrong.
  String? getError;
  String? addError;
  String? updateError;
  String? deleteError;

  /// When set, addVehicle waits for it, so a test can look at the state
  /// while the save is still running.
  Completer<void>? addGate;

  /// What the bloc asked for, in the order it asked.
  final List<String> requestedDriverIds = [];
  final List<({String vehicleType, String plateNumber})> addCalls = [];
  final List<Vehicle> updatedVehicles = [];
  final List<String> deletedIds = [];

  /// Writes down the driver id and returns [stored], or throws [getError].
  @override
  Future<Vehicle?> getVehicle(String driverId) async {
    requestedDriverIds.add(driverId);
    if (getError != null) throw Exception(getError);
    return stored;
  }

  /// Writes down the type and plate, waits for [addGate] if it is set,
  /// then returns a new vehicle with the capacity of its class, or throws
  /// [addError].
  @override
  Future<Vehicle> addVehicle({
    required String vehicleType,
    required String plateNumber,
  }) async {
    addCalls.add((vehicleType: vehicleType, plateNumber: plateNumber));
    await addGate?.future;
    if (addError != null) throw Exception(addError);
    final vehicle = Vehicle(
      id: 'vehicle${addCalls.length}',
      driverId: ownerId,
      vehicleType: vehicleType,
      plateNumber: plateNumber,
      capacityKg: VehicleClasses.of(vehicleType).capacityKg,
    );
    stored = vehicle;
    return vehicle;
  }

  /// Writes down the vehicle it was given and keeps it, or throws
  /// [updateError].
  @override
  Future<void> updateVehicle(Vehicle vehicle) async {
    updatedVehicles.add(vehicle);
    if (updateError != null) throw Exception(updateError);
    stored = vehicle;
  }

  /// Writes down the id it was given and forgets the vehicle, or throws
  /// [deleteError].
  @override
  Future<void> deleteVehicle(String vehicleId) async {
    deletedIds.add(vehicleId);
    if (deleteError != null) throw Exception(deleteError);
    stored = null;
  }
}
