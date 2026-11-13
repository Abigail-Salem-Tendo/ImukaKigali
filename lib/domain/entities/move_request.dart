// Owner: Member 3
// Entity for 'requests': id, clientId, driverId, pickupLocation, dropoffLocation, itemDescription, proposedAmount, status, clientConfirmed, driverConfirmed, createdAt.
import 'package:equatable/equatable.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/core/utils/date_parser.dart';

class MoveRequest extends Equatable {
  const MoveRequest({
    required this.id,
    required this.clientId,
    required this.driverId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.itemDescription,
    required this.vehicleType,
    required this.estimatedMinutes,
    required this.proposedAmount,
    required this.status,
    required this.clientConfirmed,
    required this.driverConfirmed,
    required this.createdAt,
  });

  final String id;
  final String clientId;

  /// Empty string until a driver accepts.
  final String driverId;
  final String pickupLocation;
  final String dropoffLocation;
  final String itemDescription;
  final String vehicleType;
  final int estimatedMinutes;
  final double proposedAmount;
  final String status; // RequestStatus.x
  final bool clientConfirmed;
  final bool driverConfirmed;
  final DateTime createdAt;

  factory MoveRequest.fromMap(String id, Map<String, dynamic> map) {
    return MoveRequest(
      id: id,
      clientId: map[Fields.clientId] as String? ?? '',
      driverId: map[Fields.driverId] as String? ?? '',
      pickupLocation: map[Fields.pickupLocation] as String? ?? '',
      dropoffLocation: map[Fields.dropoffLocation] as String? ?? '',
      itemDescription: map[Fields.itemDescription] as String? ?? '',
      vehicleType: map[Fields.vehicleType] as String? ?? '',
      estimatedMinutes: (map[Fields.estimatedMinutes] as num?)?.toInt() ?? 0,
      proposedAmount: (map[Fields.proposedAmount] as num?)?.toDouble() ?? 0,
      status: map[Fields.status] as String? ?? RequestStatus.open,
      clientConfirmed: map[Fields.clientConfirmed] as bool? ?? false,
      driverConfirmed: map[Fields.driverConfirmed] as bool? ?? false,
      createdAt: parseDate(map[Fields.createdAt]) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      Fields.clientId: clientId,
      Fields.driverId: driverId,
      Fields.pickupLocation: pickupLocation,
      Fields.dropoffLocation: dropoffLocation,
      Fields.itemDescription: itemDescription,
      Fields.vehicleType: vehicleType,
      Fields.estimatedMinutes: estimatedMinutes,
      Fields.proposedAmount: proposedAmount,
      Fields.status: status,
      Fields.clientConfirmed: clientConfirmed,
      Fields.driverConfirmed: driverConfirmed,
      Fields.createdAt: createdAt,
    };
  }

  @override
  List<Object?> get props => [
    id,
    clientId,
    driverId,
    pickupLocation,
    dropoffLocation,
    itemDescription,
    vehicleType,
    estimatedMinutes,
    proposedAmount,
    status,
    clientConfirmed,
    driverConfirmed,
    createdAt,
  ];
}
