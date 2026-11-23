import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/utils/validators.dart';

void main() {
  group('Validators.required', () {
    test('rejects empty and whitespace', () {
      expect(Validators.required(null), isNotNull);
      expect(Validators.required('   '), isNotNull);
    });
    test('uses the field name in the message', () {
      expect(
        Validators.required('', field: 'Full name'),
        'Full name is required',
      );
    });
    test('accepts text', () => expect(Validators.required('Kigali'), isNull));
  });

  group('Validators.email', () {
    test('accepts a normal address', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('  user@example.co.rw  '), isNull);
    });
    test('rejects bad addresses', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('user@'), isNotNull);
      expect(Validators.email('user.example.com'), isNotNull);
      expect(Validators.email('user@example'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('accepts 8+ chars with a letter and a number', () {
      expect(Validators.password('kigali2026'), isNull);
    });
    test('rejects short passwords', () {
      expect(Validators.password('abc123'), isNotNull);
    });
    test('rejects letters only or numbers only', () {
      expect(Validators.password('abcdefgh'), isNotNull);
      expect(Validators.password('12345678'), isNotNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('matches', () {
      expect(Validators.confirmPassword('kigali2026', 'kigali2026'), isNull);
    });
    test('does not match', () {
      expect(Validators.confirmPassword('kigali2025', 'kigali2026'), isNotNull);
    });
  });

  group('Validators.phone', () {
    test('accepts local and international Rwandan formats', () {
      expect(Validators.phone('0781234567'), isNull);
      expect(Validators.phone('+250781234567'), isNull);
      expect(Validators.phone('250731234567'), isNull);
      expect(Validators.phone('078 123-4567'), isNull);
    });
    test('rejects wrong prefixes and lengths', () {
      expect(Validators.phone(''), isNotNull);
      expect(Validators.phone('0771234567'), isNotNull);
      expect(Validators.phone('078123456'), isNotNull);
      expect(Validators.phone('+254781234567'), isNotNull);
    });
  });

  group('Validators.fullRwandanPhone', () {
    test('adds +250 once, however the number was typed', () {
      for (final typed in [
        '788 123 456',
        '0788 123 456',
        '250788123456',
        '+250 788 123 456',
      ]) {
        expect(Validators.fullRwandanPhone(typed), '+250788123456');
      }
    });
    test('stays empty when nothing was typed', () {
      expect(Validators.fullRwandanPhone('  '), '');
    });
  });
}
