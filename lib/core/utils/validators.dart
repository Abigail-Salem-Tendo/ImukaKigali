// Owner: Member 1
// Form validators: email, password, phone, required.
//
// Each one matches the signature of TextFormField.validator:
// it returns null when the value is valid, or a readable error message.
//
//   AppTextField(validator: Validators.email)
//   AppTextField(validator: (v) => Validators.required(v, field: 'Full name'))

class Validators {
  Validators._();

  /// Minimum password length.
  static const int minPasswordLength = 8;

  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final RegExp _letter = RegExp(r'[A-Za-z]');
  static final RegExp _digit = RegExp(r'\d');

  /// Rwandan mobile: 07X XXX XXXX, optionally written with +250 or 250
  /// instead of the leading 0. X after 07 is 2, 3, 8 or 9 (Airtel, MTN).
  static final RegExp _rwandaPhone = RegExp(r'^(?:\+?250|0)7[2389]\d{7}$');

  /// Fails on null, empty, or whitespace-only input.
  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!_email.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  /// At least [minPasswordLength] characters, with a letter and a number.
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < minPasswordLength) {
      return 'Password must be at least $minPasswordLength characters';
    }
    if (!_letter.hasMatch(v) || !_digit.hasMatch(v)) {
      return 'Password must contain a letter and a number';
    }
    return null;
  }

  /// Use on the "confirm password" field:
  /// validator: (v) => Validators.confirmPassword(v, passwordController.text)
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? phone(String? value) {
    final v = normalizePhone(value ?? '');
    if (v.isEmpty) return 'Phone number is required';
    if (!_rwandaPhone.hasMatch(v)) {
      return 'Enter a valid Rwandan number, e.g. 0788 123 456';
    }
    return null;
  }

  /// Strips spaces, dashes and brackets so "078 123-4567" validates.
  static String normalizePhone(String value) =>
      value.replaceAll(RegExp(r'[\s\-()]'), '');
}
