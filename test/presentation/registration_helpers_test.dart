import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/kigali_districts.dart';
import 'package:imuka_kigali/presentation/screens/driver_registration_step1/email_suggestions.dart';
import 'package:imuka_kigali/presentation/screens/driver_registration_step1/kigali_sectors.dart';

/// Unit tests for the email suggestions and the Kigali sectors used on
/// registration step 1. Run them with:
/// flutter test test/presentation/registration_helpers_test.dart
void main() {
  group('emailSuggestions', () {
    test('suggests nothing before "@" is typed', () {
      expect(emailSuggestions(''), isEmpty);
      expect(emailSuggestions('jean'), isEmpty);
      expect(emailSuggestions('@gmail'), isEmpty);
    });

    test('suggests every common service right after "@"', () {
      expect(
        emailSuggestions('jean@'),
        commonEmailDomains.map((domain) => 'jean@$domain').toList(),
      );
    });

    test('narrows the list as the driver keeps typing', () {
      expect(emailSuggestions('jean@g'), ['jean@gmail.com']);
      expect(emailSuggestions('jean@yahoo'), [
        'jean@yahoo.com',
        'jean@yahoo.fr',
      ]);
      expect(emailSuggestions('jean@GM'), ['jean@gmail.com']);
    });

    test('suggests nothing once the address is complete or unknown', () {
      expect(emailSuggestions('jean@gmail.com'), isEmpty);
      expect(emailSuggestions('jean@alu.edu'), isEmpty);
      expect(emailSuggestions('jean@@g'), isEmpty);
    });
  });

  group('Kigali sectors', () {
    test('Kigali has 35 sectors in its 3 districts', () {
      expect(kigaliSectorsByDistrict.keys, KigaliDistricts.all);
      final sectors = kigaliSectorsByDistrict.values.expand((list) => list);
      expect(sectors, hasLength(35));
      expect(sectors.toSet(), hasLength(35));
    });

    test('finds the district of a sector', () {
      expect(districtOfSector('Kimihurura'), KigaliDistricts.gasabo);
      expect(districtOfSector('Gikondo'), KigaliDistricts.kicukiro);
      expect(districtOfSector('Nyamirambo'), KigaliDistricts.nyarugenge);
      expect(districtOfSector('Nairobi'), isNull);
    });
  });
}
