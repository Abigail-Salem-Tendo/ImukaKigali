

part of 'driver_registration_bloc.dart';

enum DriverRegistrationStatus { editing, submitting, success, failure }

class DriverRegistrationState extends Equatable {
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

  // Step 1 answers
  final String fullName;
  final String phone;
  final String email;
  final String password;
  final String confirmPassword;
  final List<String> operatingHubs;

  // Step 2 answers (vehicleType is null until the driver taps a card)
  final VehicleType? vehicleType;
  final String plateNumber;

  // Screen helpers
  final bool passwordVisible;

  /// Errors stay hidden until the driver taps the button once.
  /// Red text on fields they have not touched yet would feel rude.
  final bool showStep1Errors;
  final bool showStep2Errors;

  /// A friendly message for a snackbar when saving fails.
  final String? error;

  DriverRegistrationState copyWith({
    DriverRegistrationStatus? status,
    String? fullName,
    String? phone,
    String? email,
    String? password,
    String? confirmPassword,
    List<String>? operatingHubs,
    VehicleType? vehicleType,
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
      // The error is cleared unless a new one is passed (team template).
      error: error,
    );
  }

  // ---------------------------------------------------------------------
  // Validation rules. Each getter returns null when the answer is fine,
  // or a polite message saying what to fix.
  // ---------------------------------------------------------------------

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

  /// The phone number's 9 digits without +250, e.g. "788452910".
  /// It accepts "788 452 910", "0788452910" and "+250 788 452 910".
  String get _phoneDigits {
    var digits = phone.replaceAll(RegExp(r'\D'), ''); // keep numbers only
    if (digits.startsWith('250')) {
      digits = digits.substring(3);
    }
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return digits;
  }

  String? get phoneError {
    if (phone.trim().isEmpty) {
      return 'Enter your MoMo phone number.';
    }
    // Rwanda mobile numbers: 9 digits starting with 72, 73, 78 or 79.
    if (!RegExp(r'^7[2389]\d{7}$').hasMatch(_phoneDigits)) {
      return 'Enter a Rwanda number like 788 123 456.';
    }
    return null;
  }

  /// The phone number the way we save it: "+250788452910".
  String get normalizedPhone => '+250$_phoneDigits';

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

  String? get passwordError {
    if (password.length < 8) {
      return 'Use at least 8 characters.';
    }
    return null;
  }

  String? get confirmPasswordError {
    if (confirmPassword.isEmpty) {
      return 'Type your password again.';
    }
    if (confirmPassword != password) {
      return 'The passwords do not match.';
    }
    return null;
  }

  String? get hubsError {
    if (operatingHubs.length < 2) {
      return 'Pick at least 2 hubs.';
    }
    return null;
  }

  String? get vehicleTypeError {
    if (vehicleType == null) {
      return 'Choose your vehicle class.';
    }
    return null;
  }

  String? get plateNumberError {
    if (plateNumber.trim().isEmpty) {
      return 'Enter your licence plate number.';
    }
    if (!isValidRwandaPlate(plateNumber)) {
      return 'Enter a Rwanda plate like RAD 428 E.';
    }
    return null;
  }

  bool get isStep1Valid =>
      fullNameError == null &&
          phoneError == null &&
          emailError == null &&
          passwordError == null &&
          confirmPasswordError == null &&
          hubsError == null;

  bool get isStep2Valid => vehicleTypeError == null && plateNumberError == null;

  /// The district of the first hub picked, e.g. "Gasabo".
  String get baseDistrict {
    if (operatingHubs.isEmpty) {
      return 'Gasabo';
    }
    return kigaliHubDistricts[operatingHubs.first] ?? 'Gasabo';
  }

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
