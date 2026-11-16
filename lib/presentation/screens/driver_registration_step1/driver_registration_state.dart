part of 'driver_registration_bloc.dart';

/// Where the registration is: being filled in, saving, saved, or failed.
enum DriverRegistrationStatus { editing, submitting, success, failure }

/// Everything both registration screens need to draw themselves, plus the
/// rules that decide whether each answer is correct.
class DriverRegistrationState extends Equatable {
  /// Creates a state. With no arguments it is an empty form.
  const DriverRegistrationState({
    this.status = DriverRegistrationStatus.editing,
    this.fullName = '',
    this.phone = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.operatingHubs = const [],
    this.vehicleType,
    this.plateNumber = '',
    this.passwordVisible = false,
    this.showStep1Errors = false,
    this.showStep2Errors = false,
    this.error,
  });

  final DriverRegistrationStatus status;

  // Step 1 answers.
  final String fullName;
  final String phone;
  final String email;
  final String password;
  final String confirmPassword;
  final List<String> operatingHubs;

  // Step 2 answers. vehicleType is null until the driver taps a card.
  final String? vehicleType;
  final String plateNumber;

  /// True while the password fields show their text.
  final bool passwordVisible;

  /// Error messages stay hidden until the driver taps the button once,
  /// so untouched fields are not covered in red text.
  final bool showStep1Errors;
  final bool showStep2Errors;

  /// A readable message for a snackbar when saving fails.
  final String? error;

  /// Returns a copy of this state with only the given values replaced.
  /// [error] is cleared unless a new one is passed.
  DriverRegistrationState copyWith({
    DriverRegistrationStatus? status,
    String? fullName,
    String? phone,
    String? email,
    String? password,
    String? confirmPassword,
    List<String>? operatingHubs,
    String? vehicleType,
    String? plateNumber,
    bool? passwordVisible,
    bool? showStep1Errors,
    bool? showStep2Errors,
    String? error,
  }) {
    return DriverRegistrationState(
      status: status ?? this.status,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      operatingHubs: operatingHubs ?? this.operatingHubs,
      vehicleType: vehicleType ?? this.vehicleType,
      plateNumber: plateNumber ?? this.plateNumber,
      passwordVisible: passwordVisible ?? this.passwordVisible,
      showStep1Errors: showStep1Errors ?? this.showStep1Errors,
      showStep2Errors: showStep2Errors ?? this.showStep2Errors,
      error: error,
    );
  }

  /// Checks the full name. Returns null when it is fine, or a message
  /// saying what to fix.
  String? get fullNameError {
    final name = fullName.trim();
    if (name.isEmpty) {
      return 'Enter your full legal name.';
    }
    if (name.length < 3) {
      return 'Your name looks too short.';
    }
    return null;
  }

  /// Returns the 9 digits of the phone number without the country code.
  /// "788 452 910", "0788452910" and "+250 788 452 910" all become
  /// "788452910".
  String get _phoneDigits {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('250')) {
      digits = digits.substring(3);
    }
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return digits;
  }

  /// Checks the phone number. A Rwanda mobile number has 9 digits and
  /// starts with 72, 73, 78 or 79. Returns null when it is fine.
  String? get phoneError {
    if (phone.trim().isEmpty) {
      return 'Enter your MoMo phone number.';
    }
    if (!RegExp(r'^7[2389]\d{7}$').hasMatch(_phoneDigits)) {
      return 'Enter a Rwanda number like 788 123 456.';
    }
    return null;
  }

  /// Returns the phone number the way it is saved: "+250788452910".
  String get normalizedPhone => '+250$_phoneDigits';

  /// Checks the email address. Returns null when it is fine.
  String? get emailError {
    final value = email.trim();
    if (value.isEmpty) {
      return 'Enter your email address.';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
      return 'Enter a valid email, e.g. name@gmail.com.';
    }
    return null;
  }

  /// Checks that the password has at least 8 characters.
  String? get passwordError {
    if (password.length < 8) {
      return 'Use at least 8 characters.';
    }
    return null;
  }

  /// Checks that the second password was typed and matches the first.
  String? get confirmPasswordError {
    if (confirmPassword.isEmpty) {
      return 'Type your password again.';
    }
    if (confirmPassword != password) {
      return 'The passwords do not match.';
    }
    return null;
  }

  /// Checks that the driver picked at least 2 hubs.
  String? get hubsError {
    if (operatingHubs.length < 2) {
      return 'Pick at least 2 hubs.';
    }
    return null;
  }

  /// Checks that the driver picked a vehicle type.
  String? get vehicleTypeError {
    if (vehicleType == null) {
      return 'Choose your vehicle class.';
    }
    return null;
  }

  /// Checks that the plate number was typed and has a Rwanda plate's shape.
  String? get plateNumberError {
    if (plateNumber.trim().isEmpty) {
      return 'Enter your licence plate number.';
    }
    if (!isValidRwandaPlate(plateNumber)) {
      return 'Enter a Rwanda plate like RAD 428 E.';
    }
    return null;
  }

  /// True when every answer on step 1 passes its check.
  bool get isStep1Valid =>
      fullNameError == null &&
      phoneError == null &&
      emailError == null &&
      passwordError == null &&
      confirmPasswordError == null &&
      hubsError == null;

  /// True when every answer on step 2 passes its check.
  bool get isStep2Valid => vehicleTypeError == null && plateNumberError == null;

  /// Returns the district of the first hub the driver picked, for example
  /// "Gasabo". This is saved as the driver's district.
  String get baseDistrict {
    if (operatingHubs.isEmpty) {
      return 'Gasabo';
    }
    return kigaliHubDistricts[operatingHubs.first] ?? 'Gasabo';
  }

  /// The values Equatable compares to decide if the screen must redraw.
  @override
  List<Object?> get props => [
    status,
    fullName,
    phone,
    email,
    password,
    confirmPassword,
    operatingHubs,
    vehicleType,
    plateNumber,
    passwordVisible,
    showStep1Errors,
    showStep2Errors,
    error,
  ];
}
