import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/core/constants/pricing.dart';
import 'package:imuka_kigali/domain/entities/app_user.dart';
import 'package:imuka_kigali/presentation/screens/driver_registration_step1/driver_registration_bloc.dart';

import '../helpers/fake_repositories.dart';
import '../helpers/fake_vehicle_repository.dart';

/// An AuthRepository whose register works. It writes down the values it
/// was given and throws an Exception when [registerError] is set.
class RegisteringAuthRepository extends FakeAuthRepository {
  final List<Map<String, String>> registerCalls = [];
  String? registerError;

  /// Writes down the new account's details, then returns the new user,
  /// or throws [registerError].
  @override
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
    required String district,
  }) async {
    registerCalls.add({
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
      'district': district,
    });
    if (registerError != null) throw Exception(registerError);
    return testUser(driverId, fullName, role: role);
  }
}

/// Sends the events a driver sends when they fill in both steps correctly.
void fillValidForm(DriverRegistrationBloc bloc) {
  bloc
    ..add(
      const RegistrationFieldChanged(
        RegistrationField.fullName,
        '  Jean-Claude Mugisha ',
      ),
    )
    ..add(
      const RegistrationFieldChanged(RegistrationField.phone, '0788 452 910'),
    )
    ..add(
      const RegistrationFieldChanged(
        RegistrationField.email,
        'jeanclaude@gmail.com',
      ),
    )
    ..add(
      const RegistrationFieldChanged(RegistrationField.password, 'secret123'),
    )
    ..add(
      const RegistrationFieldChanged(
        RegistrationField.confirmPassword,
        'secret123',
      ),
    )
    ..add(const RegistrationHubToggled('Kimihurura'))
    ..add(const RegistrationHubToggled('Nyabugogo'))
    ..add(const RegistrationVehicleTypeSelected(VehicleTypes.pickup))
    ..add(
      const RegistrationFieldChanged(RegistrationField.plateNumber, 'rad428e'),
    );
}

/// Unit tests for the bloc behind registration step 1 and step 2. Run them
/// with: flutter test test/presentation/driver_registration_bloc_test.dart
void main() {
  late RegisteringAuthRepository auth;
  late FakeVehicleRepository vehicles;
  late DriverRegistrationBloc bloc;

  setUp(() {
    auth = RegisteringAuthRepository();
    vehicles = FakeVehicleRepository();
    bloc = DriverRegistrationBloc(
      authRepository: auth,
      vehicleRepository: vehicles,
    );
  });

  tearDown(() => bloc.close());

  group('DriverRegistrationBloc', () {
    test('starts with an empty form', () {
      expect(bloc.state, const DriverRegistrationState());
      expect(bloc.state.isStep1Valid, isFalse);
    });

    test('tapping a hub twice picks it and then removes it', () async {
      bloc.add(const RegistrationHubToggled('Kacyiru'));
      await settle();
      expect(bloc.state.operatingHubs, ['Kacyiru']);

      bloc.add(const RegistrationHubToggled('Kacyiru'));
      await settle();
      expect(bloc.state.operatingHubs, isEmpty);
    });

    test('the eye icon shows and hides the password', () async {
      bloc.add(const RegistrationPasswordVisibilityToggled());
      await settle();
      expect(bloc.state.passwordVisible, isTrue);

      bloc.add(const RegistrationPasswordVisibilityToggled());
      await settle();
      expect(bloc.state.passwordVisible, isFalse);
    });

    test('step 1 errors only show after Continue is tapped', () async {
      expect(bloc.state.showStep1Errors, isFalse);

      bloc.add(const RegistrationStep1Continued());
      await settle();

      expect(bloc.state.showStep1Errors, isTrue);
    });

    test('an empty form shows step 2 errors and saves nothing', () async {
      bloc.add(const RegistrationSubmitted());
      await settle();

      expect(bloc.state.showStep2Errors, isTrue);
      expect(bloc.state.status, DriverRegistrationStatus.editing);
      expect(auth.registerCalls, isEmpty);
      expect(vehicles.addCalls, isEmpty);
    });

    test('goes from submitting to success on a valid form', () async {
      fillValidForm(bloc);
      await settle();

      final statuses = expectLater(
        bloc.stream.map((state) => state.status),
        emitsInOrder([
          DriverRegistrationStatus.editing,
          DriverRegistrationStatus.submitting,
          DriverRegistrationStatus.success,
        ]),
      );
      bloc.add(const RegistrationSubmitted());

      await statuses;
    });

    test('creates a driver account and saves the vehicle', () async {
      fillValidForm(bloc);
      bloc.add(const RegistrationSubmitted());
      await settle();

      final account = auth.registerCalls.single;
      expect(account['fullName'], 'Jean-Claude Mugisha');
      expect(account['email'], 'jeanclaude@gmail.com');
      expect(account['phone'], '+250788452910');
      expect(account['password'], 'secret123');
      expect(account['role'], UserRoles.driver);
      expect(account['district'], 'Gasabo');

      final vehicle = vehicles.addCalls.single;
      expect(vehicle.vehicleType, VehicleTypes.pickup);
      expect(vehicle.plateNumber, 'RAD 428 E');

      expect(bloc.state.status, DriverRegistrationStatus.success);
      expect(bloc.state.error, isNull);
    });

    test('a failed account shows its error without "Exception: "', () async {
      auth.registerError = 'That email is already used.';
      fillValidForm(bloc);
      bloc.add(const RegistrationSubmitted());
      await settle();

      expect(bloc.state.status, DriverRegistrationStatus.failure);
      expect(bloc.state.error, 'That email is already used.');
      expect(vehicles.addCalls, isEmpty);
    });

    test('a retry after a vehicle failure keeps the same account', () async {
      vehicles.addError = 'No internet connection.';
      fillValidForm(bloc);
      bloc.add(const RegistrationSubmitted());
      await settle();

      expect(bloc.state.status, DriverRegistrationStatus.failure);
      expect(bloc.state.error, 'No internet connection.');
      expect(auth.registerCalls, hasLength(1));

      vehicles.addError = null;
      bloc.add(const RegistrationSubmitted());
      await settle();

      expect(bloc.state.status, DriverRegistrationStatus.success);
      expect(auth.registerCalls, hasLength(1));
      expect(vehicles.addCalls, hasLength(2));
    });

    test('ignores a second tap while the first save is running', () async {
      vehicles.addGate = Completer<void>();
      fillValidForm(bloc);
      bloc.add(const RegistrationSubmitted());
      await settle();
      expect(bloc.state.status, DriverRegistrationStatus.submitting);

      bloc.add(const RegistrationSubmitted());
      await settle();
      vehicles.addGate!.complete();
      await settle();

      expect(bloc.state.status, DriverRegistrationStatus.success);
      expect(auth.registerCalls, hasLength(1));
      expect(vehicles.addCalls, hasLength(1));
    });
  });

  group('DriverRegistrationState checks', () {
    test('accepts a phone number written in any common way', () {
      for (final phone in ['788452910', '0788 452 910', '+250 788 452 910']) {
        final state = DriverRegistrationState(phone: phone);
        expect(state.phoneError, isNull, reason: phone);
        expect(state.normalizedPhone, '+250788452910', reason: phone);
      }
    });

    test('rejects numbers that are not Rwanda mobile numbers', () {
      expect(const DriverRegistrationState().phoneError, isNotNull);
      expect(
        const DriverRegistrationState(phone: '0712345678').phoneError,
        isNotNull,
      );
      expect(
        const DriverRegistrationState(phone: '078845').phoneError,
        isNotNull,
      );
    });

    test('rejects a name or email that is empty or the wrong shape', () {
      expect(
        const DriverRegistrationState(fullName: ' ').fullNameError,
        isNotNull,
      );
      expect(
        const DriverRegistrationState(fullName: 'Jo').fullNameError,
        isNotNull,
      );
      expect(
        const DriverRegistrationState(email: 'jean@').emailError,
        isNotNull,
      );
      expect(
        const DriverRegistrationState(email: 'jean@gmail.com').emailError,
        isNull,
      );
    });

    test('needs a password of 8 characters typed twice the same way', () {
      expect(
        const DriverRegistrationState(password: 'short').passwordError,
        isNotNull,
      );
      expect(
        const DriverRegistrationState(
          password: 'secret123',
          confirmPassword: 'secret124',
        ).confirmPasswordError,
        'The passwords do not match.',
      );
      expect(
        const DriverRegistrationState(
          password: 'secret123',
          confirmPassword: 'secret123',
        ).confirmPasswordError,
        isNull,
      );
    });

    test('needs at least 2 hubs', () {
      expect(
        const DriverRegistrationState(operatingHubs: ['Kacyiru']).hubsError,
        isNotNull,
      );
      expect(
        const DriverRegistrationState(operatingHubs: ['Kacyiru', 'Gikondo'])
            .hubsError,
        isNull,
      );
    });

    test('uses the district of the first hub as the base district', () {
      expect(
        const DriverRegistrationState(
          operatingHubs: ['Nyabugogo', 'Kimihurura'],
        ).baseDistrict,
        'Nyarugenge',
      );
      expect(const DriverRegistrationState().baseDistrict, 'Gasabo');
    });

    test('step 2 needs a vehicle class and a valid plate', () {
      expect(
        const DriverRegistrationState(plateNumber: 'RAD 428 E').isStep2Valid,
        isFalse,
      );
      expect(
        const DriverRegistrationState(
          vehicleType: VehicleTypes.van,
          plateNumber: 'KAD 428 E',
        ).isStep2Valid,
        isFalse,
      );
      expect(
        const DriverRegistrationState(
          vehicleType: VehicleTypes.van,
          plateNumber: 'RAD 428 E',
        ).isStep2Valid,
        isTrue,
      );
    });
  });
}
