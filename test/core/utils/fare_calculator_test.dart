import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/kigali_areas.dart';
import 'package:imuka_kigali/core/constants/pricing.dart';
import 'package:imuka_kigali/core/utils/fare_calculator.dart';

void main() {
  KigaliArea area(String name) =>
      KigaliAreas.all.firstWhere((a) => a.name == name);

  final cityCentre = area('City Centre');
  final remera = area('Remera');
  final kacyiru = area('Kacyiru');

  /// Every pair of different areas, in both directions.
  final routes = [
    for (final a in KigaliAreas.all)
      for (final b in KigaliAreas.all)
        if (a.name != b.name) (a, b),
  ];

  group('distanceKm', () {
    test('is zero for the same area', () {
      expect(FareCalculator.distanceKm(remera, remera), 0);
    });

    test('one degree of latitude is about 111 km', () {
      const a = KigaliArea(name: 'A', latitude: 0, longitude: 30);
      const b = KigaliArea(name: 'B', latitude: 1, longitude: 30);
      expect(FareCalculator.distanceKm(a, b), closeTo(111.19, 0.01));
    });

    test('City Centre to Remera is about 5.86 km', () {
      expect(
        FareCalculator.distanceKm(cityCentre, remera),
        closeTo(5.86, 0.01),
      );
    });

    test('is the same in both directions', () {
      for (final (a, b) in routes) {
        expect(
          FareCalculator.distanceKm(a, b),
          closeTo(FareCalculator.distanceKm(b, a), 1e-9),
          reason: '${a.name} <-> ${b.name}',
        );
      }
    });
  });

  group('roadDistanceKm', () {
    test('applies the road factor', () {
      expect(FareCalculator.roadDistanceKm(10), closeTo(13, 1e-9));
    });

    test('keeps zero at zero', () {
      expect(FareCalculator.roadDistanceKm(0), 0);
    });
  });

  group('estimatedMinutes', () {
    test('is only loading time for no distance', () {
      expect(FareCalculator.estimatedMinutes(0), Pricing.loadingMinutes);
    });

    test('rounds part of a minute up', () {
      // 1 km straight = 1.3 km road = 3.9 minutes, so 4 + 15 loading.
      expect(FareCalculator.estimatedMinutes(1), 19);
    });

    test('adds driving time to loading time', () {
      // 5 km straight = 6.5 km road = 19.5 minutes, so 20 + 15 loading.
      expect(FareCalculator.estimatedMinutes(5), 35);
    });
  });

  group('calculate', () {
    test('prices City Centre to Remera for each vehicle', () {
      const expected = {
        VehicleTypes.tricycle: 3000.0,
        VehicleTypes.pickup: 5300.0,
        VehicleTypes.van: 6900.0,
        VehicleTypes.truck: 10700.0,
      };

      expected.forEach((vehicle, amount) {
        final fare = FareCalculator.calculate(
          pickup: cityCentre,
          dropoff: remera,
          vehicleType: vehicle,
        );
        expect(fare.proposedAmount, amount, reason: vehicle);
        expect(fare.estimatedMinutes, 38, reason: vehicle);
      });
    });

    test('uses the minimum fare on a short trip', () {
      final fare = FareCalculator.calculate(
        pickup: cityCentre,
        dropoff: kacyiru,
        vehicleType: VehicleTypes.tricycle,
      );
      expect(fare.proposedAmount, Pricing.minimumFare);
      expect(fare.estimatedMinutes, 20);
    });

    test('goes above the minimum when the distance earns it', () {
      final fare = FareCalculator.calculate(
        pickup: cityCentre,
        dropoff: kacyiru,
        vehicleType: VehicleTypes.truck,
      );
      expect(fare.proposedAmount, 2300);
    });

    test('the same area costs the minimum fare and loading time', () {
      final fare = FareCalculator.calculate(
        pickup: remera,
        dropoff: remera,
        vehicleType: VehicleTypes.truck,
      );
      expect(fare.proposedAmount, Pricing.minimumFare);
      expect(fare.estimatedMinutes, Pricing.loadingMinutes);
    });

    test('rejects an unknown vehicle type', () {
      for (final vehicle in ['', 'bicycle', 'Pickup']) {
        expect(
          () => FareCalculator.calculate(
            pickup: cityCentre,
            dropoff: remera,
            vehicleType: vehicle,
          ),
          throwsArgumentError,
          reason: vehicle,
        );
      }
    });

    test('every vehicle has a rate', () {
      expect(Pricing.ratePerKm.keys, unorderedEquals(VehicleTypes.all));
    });

    test('every route is a whole 100 RWF at or above the minimum', () {
      for (final (a, b) in routes) {
        for (final vehicle in VehicleTypes.all) {
          final amount = FareCalculator.calculate(
            pickup: a,
            dropoff: b,
            vehicleType: vehicle,
          ).proposedAmount;
          final label = '${a.name} -> ${b.name} ($vehicle)';
          expect(
            amount,
            greaterThanOrEqualTo(Pricing.minimumFare),
            reason: label,
          );
          expect(amount % 100, 0, reason: label);
        }
      }
    });

        test('a higher rate never costs less on any route', () {
      final byRate = [...VehicleTypes.all]
        ..sort(
          (a, b) => Pricing.ratePerKm[a]!.compareTo(Pricing.ratePerKm[b]!),
        );

      for (final (a, b) in routes) {
        final prices = [
          for (final vehicle in byRate)
            FareCalculator.calculate(
              pickup: a,
              dropoff: b,
              vehicleType: vehicle,
            ).proposedAmount,
        ];
        for (var i = 1; i < prices.length; i++) {
          expect(
            prices[i],
            greaterThanOrEqualTo(prices[i - 1]),
            reason: '${a.name} -> ${b.name}',
          );
        }
      }
    });

    test('a route costs the same in both directions', () {
      for (final (a, b) in routes) {
        for (final vehicle in VehicleTypes.all) {
          final there = FareCalculator.calculate(
            pickup: a,
            dropoff: b,
            vehicleType: vehicle,
          );
          final back = FareCalculator.calculate(
            pickup: b,
            dropoff: a,
            vehicleType: vehicle,
          );
          expect(there.proposedAmount, back.proposedAmount);
          expect(there.estimatedMinutes, back.estimatedMinutes);
        }
      }
    });
  });
}
