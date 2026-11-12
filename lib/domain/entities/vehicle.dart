
import 'package:equatable/equatable.dart';

import '../../core/constants/firestore_constants.dart';

/// The four vehicle classes from the ride-booking design.
///
/// Drivers pick one when they register. Clients pick one when they book,
/// and its [ratePerMinuteRwf] decides the fare.
/// Firestore stores the enum's name: 'tricycle', 'pickup', 'boxTruck'
/// or 'largeTruck'.
enum VehicleType {
  // EXAMPLE RATES. Your group agrees the real prices and changes them
  // here only: every screen and the fare calculation read them from here.
  tricycle(
    label: 'Tricycle Cargo (Bajaj / TVS)',
    shortLabel: 'Tricycle',
    plateSeries: 'Motorbike / Tricycle Plate Series',
    description: 'Up to 350 kg • A few items, boxes or a fridge. '
        'Agile on Kigali hills.',
    capacityKg: 350,
    ratePerMinuteRwf: 150,
    photo: 'assets/vehicles/tricycle.jpg',
  ),
  pickup(
    label: 'Pickup (Daihatsu Delta / Hilux)',
    shortLabel: 'Pickup',
    plateSeries: 'Automobile Standard Plate Series',
    description: 'Up to 1.5 t • Open back. Ideal for 1–2 room '
        'apartment moves.',
    capacityKg: 1500,
    ratePerMinuteRwf: 400,
    photo: 'assets/vehicles/pickup.jpg',
  ),
  boxTruck(
    label: 'Box Truck (Isuzu / Canter)',
    shortLabel: 'Box Truck',
    plateSeries: 'Commercial Automobile Plate',
    description: 'Up to 3 t • Covered and rain-safe. Fits a 3–4 room '
        'house.',
    capacityKg: 3000,
    ratePerMinuteRwf: 700,
    photo: 'assets/vehicles/box_truck.jpg',
  ),
  largeTruck(
    label: 'Large Truck (Fuso)',
    shortLabel: 'Large Truck',
    plateSeries: 'Commercial Automobile Plate',
    description: 'Up to 5 t • High sides. Whole houses and office '
        'moves.',
    capacityKg: 5000,
    ratePerMinuteRwf: 1000,
    photo: 'assets/vehicles/large_truck.jpg',
  );

  const VehicleType({
    required this.label,
    required this.shortLabel,
    required this.plateSeries,
    required this.description,
    required this.capacityKg,
    required this.ratePerMinuteRwf,
    required this.photo,
  });

  final String label;
  final String shortLabel;
  final String plateSeries;
  final String description;

  /// Where the vehicle's photo lives inside the app (see pubspec.yaml).
  final String photo;

  /// The most this class of vehicle can carry, in kilograms.
  final int capacityKg;

  /// What the client pays for each minute of the move, in Rwandan francs.
  final int ratePerMinuteRwf;

  /// e.g. "400 RWF / min"
  String get rateLabel => '${formatRwf(ratePerMinuteRwf)} / min';

  /// The fare for a move that lasted [duration].
  ///
  /// A started minute counts as a full minute, so 61 seconds costs
  /// 2 minutes. Teammates call this when the trip ends, for example:
  /// VehicleType.pickup.fareFor(completedAt.difference(startedAt))
  int fareFor(Duration duration) {
    if (duration.isNegative) {
      return 0;
    }
    final minutes = (duration.inSeconds / 60).ceil();
    return minutes * ratePerMinuteRwf;
  }

  /// Turns the word saved in Firestore back into a VehicleType.
  /// An unknown word falls back to pickup, so the app never crashes.
  static VehicleType fromName(String? name) {
    return VehicleType.values.firstWhere(
          (type) => type.name == name,
      orElse: () => VehicleType.pickup,
    );
  }
}

/// Writes an amount of money the Rwandan way: 24000 -> "24,000 RWF".
String formatRwf(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    // Put a comma before every group of 3 digits, counting from the right.
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  final sign = amount < 0 ? '-' : '';
  return '$sign$buffer RWF';
}

/// The Kigali hubs a driver can work from, and the district each one is in.
const Map<String, String> kigaliHubDistricts = {
  'Kimihurura': 'Gasabo',
  'Remera / Gisimenti': 'Gasabo',
  'Kacyiru': 'Gasabo',
  'Nyabugogo': 'Nyarugenge',
  'Nyamirambo': 'Nyarugenge',
  'Gikondo': 'Kicukiro',
  'Kicukiro Centre': 'Kicukiro',
};

/// Removes spaces and makes letters capital: " rad428e " -> "RAD428E".
String _compactPlate(String input) {
  return input.replaceAll(RegExp(r'\s+'), '').toUpperCase();
}

/// True for Rwanda plates such as "RAD 428 E". Spaces are optional.
///
/// The pattern means: R, then 1 or 2 letters, then 3 digits, then 1 letter.
bool isValidRwandaPlate(String input) {
  return RegExp(r'^R[A-Z]{1,2}\d{3}[A-Z]$').hasMatch(_compactPlate(input));
}

/// Writes a plate the standard way: "rad428e" -> "RAD 428 E".
String formatRwandaPlate(String input) {
  final plate = _compactPlate(input);
  if (!isValidRwandaPlate(plate)) {
    return plate; // Not a real plate, so leave it as it is.
  }
  final letters = plate.substring(0, plate.length - 4); // "RAD"
  final digits = plate.substring(plate.length - 4, plate.length - 1); // "428"
  final lastLetter = plate.substring(plate.length - 1); // "E"
  return '$letters $digits $lastLetter';
}

/// One document in the 'vehicles' collection.
///
/// Equatable lets Dart compare two vehicles by their values, which the
/// bloc tests need ("is the vehicle in the state the one we expect?").
class Vehicle extends Equatable {
  const Vehicle({
    required this.id,
    required this.driverId,
    required this.vehicleType,
    required this.plateNumber,
    required this.capacityKg,
    this.operatingHubs = const [],
  });

  /// The Firestore document ID (the primary key).
  final String id;

  /// The driver who owns this vehicle (foreign key -> users.uid).
  final String driverId;

  final VehicleType vehicleType;

  /// Always saved the standard way, e.g. "RAD 428 E".
  final String plateNumber;

  final int capacityKg;

  /// The hubs this driver works from, e.g. ['Kimihurura', 'Kacyiru'].
  final List<String> operatingHubs;

  /// The district of the first hub, e.g. "Gasabo".
  /// Null when the driver has not picked any hubs yet.
  String? get baseDistrict {
    if (operatingHubs.isEmpty) {
      return null;
    }
    return kigaliHubDistricts[operatingHubs.first];
  }

  /// Firestore Map -> Vehicle (used when reading).
  factory Vehicle.fromMap(String id, Map<String, dynamic> map) {
    final type = VehicleType.fromName(map[Fields.vehicleType] as String?);
    return Vehicle(
      id: id,
      driverId: map[Fields.driverId] as String? ?? '',
      vehicleType: type,
      plateNumber: map[Fields.plateNumber] as String? ?? '',
      // Firestore can send numbers as int or double; toInt() handles both.
      capacityKg: (map[Fields.capacityKg] as num?)?.toInt() ?? type.capacityKg,
      operatingHubs: List<String>.from(
        map[Fields.operatingHubs] as List? ?? const [],
      ),
    );
  }

  /// Vehicle -> Firestore Map (used when saving).
  /// The id is not inside the map: it is the document's name.
  Map<String, dynamic> toMap() {
    return {
      Fields.driverId: driverId,
      Fields.vehicleType: vehicleType.name,
      Fields.plateNumber: plateNumber,
      Fields.capacityKg: capacityKg,
      Fields.operatingHubs: operatingHubs,
    };
  }

  /// A copy of this vehicle with only some values changed.
  Vehicle copyWith({
    VehicleType? vehicleType,
    String? plateNumber,
    int? capacityKg,
    List<String>? operatingHubs,
  }) {
    return Vehicle(
      id: id,
      driverId: driverId,
      vehicleType: vehicleType ?? this.vehicleType,
      plateNumber: plateNumber ?? this.plateNumber,
      capacityKg: capacityKg ?? this.capacityKg,
      operatingHubs: operatingHubs ?? this.operatingHubs,
    );
  }

  @override
  List<Object?> get props => [
    id,
    driverId,
    vehicleType,
    plateNumber,
    capacityKg,
    operatingHubs,
  ];
}
