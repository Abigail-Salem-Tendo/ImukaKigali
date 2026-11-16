// Owner: Member 2
// Entity for 'vehicles': id, driverId, vehicleType, plateNumber, capacityKg. Has fromMap(id, map) + toMap().
import 'package:equatable/equatable.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';

/// One document in the 'vehicles' collection: the vehicle a driver registered.
class Vehicle extends Equatable {
  /// Creates a vehicle from values the app already has.
  const Vehicle({
    required this.id,
    required this.driverId,
    required this.vehicleType,
    required this.plateNumber,
    required this.capacityKg,
  });

  /// The Firestore document ID (the primary key).
  final String id;

  /// The driver who owns this vehicle (foreign key to users).
  final String driverId;

  /// One of VehicleTypes.all, for example 'pickup'.
  final String vehicleType;

  /// The licence plate, written the standard way, for example "RAD 428 E".
  final String plateNumber;

  /// The most this vehicle can carry, in kilograms.
  final double capacityKg;

  /// Builds a Vehicle from a Firestore document.
  /// [id] is the document ID and [map] holds the document's fields.
  /// A missing field becomes an empty value, so the app never crashes.
  factory Vehicle.fromMap(String id, Map<String, dynamic> map) {
    return Vehicle(
      id: id,
      driverId: map[Fields.driverId] as String? ?? '',
      vehicleType: map[Fields.vehicleType] as String? ?? '',
      plateNumber: map[Fields.plateNumber] as String? ?? '',
      capacityKg: (map[Fields.capacityKg] as num?)?.toDouble() ?? 0,
    );
  }

  /// Turns this vehicle into the fields saved in Firestore.
  /// The id is left out because it is the document's name, not a field.
  Map<String, dynamic> toMap() {
    return {
      Fields.driverId: driverId,
      Fields.vehicleType: vehicleType,
      Fields.plateNumber: plateNumber,
      Fields.capacityKg: capacityKg,
    };
  }

  /// Returns a copy of this vehicle with only the given values replaced.
  /// The id and the owner never change, so they cannot be passed in.
  Vehicle copyWith({
    String? vehicleType,
    String? plateNumber,
    double? capacityKg,
  }) {
    return Vehicle(
      id: id,
      driverId: driverId,
      vehicleType: vehicleType ?? this.vehicleType,
      plateNumber: plateNumber ?? this.plateNumber,
      capacityKg: capacityKg ?? this.capacityKg,
    );
  }

  /// The values Equatable compares to decide if two vehicles are equal.
  @override
  List<Object?> get props => [
    id,
    driverId,
    vehicleType,
    plateNumber,
    capacityKg,
  ];
}
