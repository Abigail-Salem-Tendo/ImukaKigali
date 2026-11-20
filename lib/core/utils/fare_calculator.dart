import 'dart:math';

import 'package:imuka_kigali/core/constants/kigali_areas.dart';
import 'package:imuka_kigali/core/constants/pricing.dart';

/// The only place where distance, time and price are calculated.
/// No screen or bloc does this maths itself.
class FareCalculator {
  FareCalculator._();

  static const double _earthRadiusKm = 6371;
  static const double _roundTo = 100;

  /// Returns the values saved on the request: estimatedMinutes and proposedAmount.
  static ({int estimatedMinutes, double proposedAmount}) calculate({
    required KigaliArea pickup,
    required KigaliArea dropoff,
    required String vehicleType,
  }) {
    final rate = Pricing.ratePerKm[vehicleType];
    if (rate == null) {
      throw ArgumentError.value(
        vehicleType,
        'vehicleType',
        'Unknown vehicle type',
      );
    }

    final straightKm = distanceKm(pickup, dropoff);
    final roadKm = roadDistanceKm(straightKm);
    final rounded = (roadKm * rate / _roundTo).round() * _roundTo;
    final amount = max(rounded, Pricing.minimumFare);

    return (
      estimatedMinutes: estimatedMinutes(straightKm),
      proposedAmount: amount,
    );
  }

  /// straight-line (haversine) distance between two areas.
  /// Later upgrade replace the body with the Google Directions API.
  static double distanceKm(KigaliArea a, KigaliArea b) {
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLng = _toRadians(b.longitude - a.longitude);
    final h =
        pow(sin(dLat / 2), 2) +
        cos(_toRadians(a.latitude)) *
            cos(_toRadians(b.latitude)) *
            pow(sin(dLng / 2), 2);
    return 2 * _earthRadiusKm * asin(sqrt(h));
  }

  /// straight-line distance converted to approximate road distance. The price is per kilometre of this distance.
  static double roadDistanceKm(double straightKm) =>
      straightKm * Pricing.roadFactor;

  /// driving time plus loading time.
  static int estimatedMinutes(double straightKm) {
    final driving = (roadDistanceKm(straightKm) / Pricing.averageSpeedKmh * 60)
        .ceil();
    return driving + Pricing.loadingMinutes;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}
