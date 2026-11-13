// Owner: Member 2
// Entity for 'vehicles': id, driverId, vehicleType, plateNumber, capacityKg. Has fromMap(id, map) + toMap().
import 'package:equatable/equatable.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';

class Vehicle extends Equatable {
  const Vehicle({
    required this.id,
    required this.driverId,
    required this.vehicleType,
    required this.plateNumber,
    required this.capacityKg,
  });

  final String id;
  final String driverId;
  final String vehicleType; // one of VehicleTypes.all
  final String plateNumber;
  final double capacityKg;

  factory Vehicle.fromMap(String id, Map<String, dynamic> map) {
    return Vehicle(
      id: id,
      driverId: map[Fields.driverId] as String? ?? '',
      vehicleType: map[Fields.vehicleType] as String? ?? '',
      plateNumber: map[Fields.plateNumber] as String? ?? '',
      capacityKg: (map[Fields.capacityKg] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      Fields.driverId: driverId,
      Fields.vehicleType: vehicleType,
      Fields.plateNumber: plateNumber,
      Fields.capacityKg: capacityKg,
    };
  }

  @override
  List<Object?> get props => [
    id,
    driverId,
    vehicleType,
    plateNumber,
    capacityKg,
  ];
}
