import 'package:imuka_kigali/core/constants/pricing.dart';

/// Everything the screens show about one vehicle type: its name, photo,
/// capacity and price. The type strings and the prices come from
/// pricing.dart, so they are never typed a second time here.
class VehicleClass {
  /// Describes one vehicle type.
  const VehicleClass({
    required this.type,
    required this.label,
    required this.shortLabel,
    required this.plateSeries,
    required this.description,
    required this.capacityKg,
    required this.photo,
  });

  /// One of VehicleTypes.all. This is the string saved in Firestore.
  final String type;

  /// The full name shown on the vehicle cards.
  final String label;

  /// A short name for tight spaces, for example "Pickup".
  final String shortLabel;

  /// The kind of licence plate this vehicle type carries.
  final String plateSeries;

  /// One sentence about what the vehicle is good for.
  final String description;

  /// The most this vehicle type can carry, in kilograms.
  final double capacityKg;

  /// The path of the vehicle's photo inside the app's assets.
  final String photo;

  /// The price per minute for this vehicle type, read from Pricing.
  /// Returns 0 if the type has no price yet.
  double get ratePerMinute => Pricing.ratePerMinute[type] ?? 0;

  /// The price per minute as text, for example "90 RWF / min".
  String get rateLabel => '${_formatRwf(ratePerMinute.round())} / min';

  /// The capacity as text, for example "350 kg" or "1.5 t".
  String get capacityLabel {
    if (capacityKg < 1000) {
      return '${capacityKg.round()} kg';
    }
    final tonnes = capacityKg / 1000;
    final isWholeNumber = tonnes == tonnes.roundToDouble();
    return '${isWholeNumber ? tonnes.round() : tonnes.toStringAsFixed(1)} t';
  }
}

/// The list of vehicle types a driver can register.
class VehicleClasses {
  VehicleClasses._();

  /// Every vehicle type, ordered from the smallest to the biggest.
  static const List<VehicleClass> all = [
    VehicleClass(
      type: VehicleTypes.tricycle,
      label: 'Tricycle Cargo (Bajaj / TVS)',
      shortLabel: 'Tricycle',
      plateSeries: 'Motorbike / Tricycle Plate Series',
      description: 'A few items, boxes or a fridge. Agile on Kigali hills.',
      capacityKg: 350,
      photo: 'assets/vehicles/tricycle.jpg',
    ),
    VehicleClass(
      type: VehicleTypes.pickup,
      label: 'Pickup (Daihatsu Delta / Hilux)',
      shortLabel: 'Pickup',
      plateSeries: 'Automobile Standard Plate Series',
      description: 'Open back. Ideal for 1–2 room apartment moves.',
      capacityKg: 1500,
      photo: 'assets/vehicles/pickup.jpg',
    ),
    VehicleClass(
      type: VehicleTypes.van,
      label: 'Box Van (Isuzu / Canter)',
      shortLabel: 'Van',
      plateSeries: 'Commercial Automobile Plate',
      description: 'Covered and rain-safe. Fits a 3–4 room house.',
      capacityKg: 3000,
      photo: 'assets/vehicles/van.jpg',
    ),
    VehicleClass(
      type: VehicleTypes.truck,
      label: 'Large Truck (Fuso)',
      shortLabel: 'Truck',
      plateSeries: 'Commercial Automobile Plate',
      description: 'High sides. Whole houses and office moves.',
      capacityKg: 5000,
      photo: 'assets/vehicles/truck.jpg',
    ),
  ];

  /// Finds the class for a vehicle type string such as 'pickup'.
  /// An unknown string falls back to the pickup, so the app never crashes.
  static VehicleClass of(String type) {
    return all.firstWhere(
      (vehicleClass) => vehicleClass.type == type,
      orElse: () => all[1],
    );
  }
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

/// Writes an amount of money the Rwandan way: 24000 becomes "24,000 RWF".
String _formatRwf(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    // A comma goes before every group of 3 digits, counting from the right.
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  final sign = amount < 0 ? '-' : '';
  return '$sign$buffer RWF';
}

/// Removes the spaces from a plate and makes its letters capital:
/// " rad 428 e " becomes "RAD428E".
String _compactPlate(String input) {
  return input.replaceAll(RegExp(r'\s+'), '').toUpperCase();
}

/// Checks that [input] has the shape of a Rwanda plate such as "RAD 428 E".
/// The shape is: R, then 1 or 2 letters, then 3 digits, then 1 letter.
/// Spaces and small letters are accepted.
bool isValidRwandaPlate(String input) {
  return RegExp(r'^R[A-Z]{1,2}\d{3}[A-Z]$').hasMatch(_compactPlate(input));
}

/// Writes a plate the standard way: "rad428e" becomes "RAD 428 E".
/// Text that is not a valid plate is returned without spaces, in capitals.
String formatRwandaPlate(String input) {
  final plate = _compactPlate(input);
  if (!isValidRwandaPlate(plate)) {
    return plate;
  }
  final letters = plate.substring(0, plate.length - 4);
  final digits = plate.substring(plate.length - 4, plate.length - 1);
  final lastLetter = plate.substring(plate.length - 1);
  return '$letters $digits $lastLetter';
}
