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
    });
  });

  group('Vehicle classes', () {
    test('there is one class for every vehicle type', () {
      final types = VehicleClasses.all.map((c) => c.type).toList();
      expect(types, VehicleTypes.all);
    });

    test('every class reads its price from Pricing', () {
      for (final vehicleClass in VehicleClasses.all) {
        expect(
          vehicleClass.ratePerMinute,
          Pricing.ratePerMinute[vehicleClass.type],
        );
      }
    });

    test('a bigger vehicle can carry more', () {
      final capacities = VehicleClasses.all.map((c) => c.capacityKg).toList();
      expect(capacities, orderedEquals([...capacities]..sort()));
    });

    test('an unknown type falls back to the pickup', () {
      expect(VehicleClasses.of('spaceship').type, VehicleTypes.pickup);
    });

    test('writes capacities and amounts as readable text', () {
      expect(VehicleClasses.of(VehicleTypes.tricycle).capacityLabel, '350 kg');
      expect(VehicleClasses.of(VehicleTypes.pickup).capacityLabel, '1.5 t');
      expect(VehicleClasses.of(VehicleTypes.van).capacityLabel, '3 t');
      expect(formatRwf(24000), '24,000 RWF');
      expect(formatRwf(400), '400 RWF');
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
