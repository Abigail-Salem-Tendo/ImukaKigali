/// Vehicle type strings. Same strings in vehicles.vehicleType and requests.vehicleType.
class VehicleTypes {
  VehicleTypes._();

  static const String tricycle = 'tricycle';
  static const String pickup = 'pickup';
  static const String van = 'van';
  static const String truck = 'truck';

  static const List<String> all = [tricycle, pickup, van, truck];
}

/// Pricing numbers used only by FareCalculator.
/// The rates are PLACEHOLDERS and the currency is RWF
class Pricing {
  Pricing._();

  /// Price per km of road distance. A bigger vehicle has a bigger rate.
  static const Map<String, double> ratePerKm = {
    VehicleTypes.tricycle: 400,
    VehicleTypes.pickup: 700,
    VehicleTypes.van: 900,
    VehicleTypes.truck: 1400,
  };

  /// Straight-line distance is multiplied by this to approximate road distance.
  static const double roadFactor = 1.3;

  static const double averageSpeedKmh = 20;

  /// Fixed time added for loading and unloading.
  static const int loadingMinutes = 15;

  /// The price is never below this (RWF).
  static const double minimumFare = 2000;
}
