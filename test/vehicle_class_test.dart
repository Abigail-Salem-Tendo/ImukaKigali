import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/pricing.dart';
import 'package:imuka_kigali/domain/entities/vehicle.dart';
import 'package:imuka_kigali/domain/entities/vehicle_class.dart';

/// Unit tests for the vehicle classes, the plate rules and the Vehicle
/// entity. Run them with: flutter test test/vehicle_class_test.dart
void main() {
  group('Rwanda plate numbers', () {
    test('accepts real plate shapes, with or without spaces', () {
      expect(isValidRwandaPlate('RAD 428 E'), isTrue);
      expect(isValidRwandaPlate('rad428e'), isTrue);
      expect(isValidRwandaPlate('RC 123 A'), isTrue);
    });

    test('rejects plates that are empty or the wrong shape', () {
      expect(isValidRwandaPlate(''), isFalse);
      expect(isValidRwandaPlate('KAD 428 E'), isFalse);
      expect(isValidRwandaPlate('RAD 42 E'), isFalse);
      expect(isValidRwandaPlate('RAD 428'), isFalse);
    });

    test('writes plates the standard way', () {
      expect(formatRwandaPlate(' rad428e '), 'RAD 428 E');
      expect(formatRwandaPlate('rc123a'), 'RC 123 A');
      expect(formatRwandaPlate('rd204e'), 'RD 204 E');
    });

    test('a moto plate has one letter after the R, a car plate two', () {
      expect(isValidRwandaPlate('RD 204 E', motoPlate: true), isTrue);
      expect(isValidRwandaPlate('RAD 428 E', motoPlate: true), isFalse);
      expect(isValidRwandaPlate('RAD 428 E', motoPlate: false), isTrue);
      expect(isValidRwandaPlate('RD 204 E', motoPlate: false), isFalse);
    });

    test('a tricycle needs a moto plate, the other vehicles a car plate', () {
      final tricycle = VehicleClasses.of(VehicleTypes.tricycle);
      final pickup = VehicleClasses.of(VehicleTypes.pickup);

      expect(tricycle.acceptsPlate('rd204e'), isTrue);
      expect(tricycle.acceptsPlate('RAD 428 E'), isFalse);
      expect(tricycle.plateError, 'Enter a Rwanda plate like RD 204 E.');
      expect(pickup.acceptsPlate('RD 204 E'), isFalse);
      expect(pickup.plateExample, 'RAD 428 E');
    });
  });

  group('Vehicle classes', () {
    test('there is one class for every vehicle type', () {
      final types = VehicleClasses.all.map((c) => c.type).toList();
      expect(types, VehicleTypes.all);
    });

    test('every class reads its price from Pricing', () {
      for (final vehicleClass in VehicleClasses.all) {
        expect(vehicleClass.ratePerKm, Pricing.ratePerKm[vehicleClass.type]);
      }
    });

    test('a bigger vehicle can carry more', () {
      final capacities = VehicleClasses.all.map((c) => c.capacityKg).toList();
      expect(capacities, orderedEquals([...capacities]..sort()));
    });

    test('an unknown type falls back to the pickup', () {
      expect(VehicleClasses.of('spaceship').type, VehicleTypes.pickup);
    });

    test('writes capacities as readable text', () {
      expect(VehicleClasses.of(VehicleTypes.tricycle).capacityLabel, '350 kg');
      expect(VehicleClasses.of(VehicleTypes.pickup).capacityLabel, '1.5 t');
      expect(VehicleClasses.of(VehicleTypes.van).capacityLabel, '3 t');
    });

    test('writes the rate per km with a comma every 3 digits', () {
      for (final vehicleClass in VehicleClasses.all) {
        expect(
          vehicleClass.rateLabel,
          matches(RegExp(r'^\d{1,3}(,\d{3})* RWF / km$')),
        );
      }
    });
  });

  group('Vehicle', () {
    const vehicle = Vehicle(
      id: 'v1',
      driverId: 'driver-1',
      vehicleType: VehicleTypes.pickup,
      plateNumber: 'RAD 428 E',
      capacityKg: 1500,
    );

    test('comes back the same after a trip to Firestore and back', () {
      expect(Vehicle.fromMap('v1', vehicle.toMap()), vehicle);
    });

    test('copyWith changes only the values it is given', () {
      final changed = vehicle.copyWith(plateNumber: 'RAC 119 B');

      expect(changed.plateNumber, 'RAC 119 B');
      expect(changed.vehicleType, vehicle.vehicleType);
      expect(changed.id, vehicle.id);
    });
  });
}
