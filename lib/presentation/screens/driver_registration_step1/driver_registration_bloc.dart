import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imuka_kigali/core/constants/firestore_constants.dart';
import 'package:imuka_kigali/domain/entities/vehicle_class.dart';
import 'package:imuka_kigali/domain/repositories/auth_repository.dart';
import 'package:imuka_kigali/domain/repositories/vehicle_repository.dart';

part 'driver_registration_event.dart';
part 'driver_registration_state.dart';

/// The logic shared by registration step 1 and step 2. It remembers what
/// the driver typed on step 1 while they fill in step 2, and on
/// "Complete Registration" it creates the account and saves the vehicle.
class DriverRegistrationBloc
    extends Bloc<DriverRegistrationEvent, DriverRegistrationState> {
  /// Creates the bloc with an empty form and links each event to the
  /// method that handles it.
  DriverRegistrationBloc({
    required this._authRepository,
    required this._vehicleRepository,
  }) : super(const DriverRegistrationState()) {
    on<RegistrationFieldChanged>(_onFieldChanged);
    on<RegistrationHubToggled>(_onHubToggled);
    on<RegistrationPasswordVisibilityToggled>(_onPasswordVisibilityToggled);
    on<RegistrationStep1Continued>(_onStep1Continued);
    on<RegistrationVehicleTypeSelected>(_onVehicleTypeSelected);
    on<RegistrationSubmitted>(_onSubmitted);
  }

  final AuthRepository _authRepository;
  final VehicleRepository _vehicleRepository;

  /// True once the account exists. It stops a second tap from creating
  /// the same account twice when only the vehicle failed to save.
  bool _accountCreated = false;

  /// Stores the new text of the field the driver typed in.
  void _onFieldChanged(
    RegistrationFieldChanged event,
    Emitter<DriverRegistrationState> emit,
  ) {
    emit(switch (event.field) {
      RegistrationField.fullName => state.copyWith(fullName: event.value),
      RegistrationField.phone => state.copyWith(phone: event.value),
      RegistrationField.email => state.copyWith(email: event.value),
      RegistrationField.password => state.copyWith(password: event.value),
      RegistrationField.confirmPassword => state.copyWith(
        confirmPassword: event.value,
      ),
      RegistrationField.plateNumber => state.copyWith(plateNumber: event.value),
    });
  }

  /// Adds the tapped hub to the chosen hubs, or removes it if it was
  /// already chosen. A new list is made so the state counts as changed.
  void _onHubToggled(
    RegistrationHubToggled event,
    Emitter<DriverRegistrationState> emit,
  ) {
    final hubs = [...state.operatingHubs];
    if (hubs.contains(event.hub)) {
      hubs.remove(event.hub);
    } else {
      hubs.add(event.hub);
    }
    emit(state.copyWith(operatingHubs: hubs));
  }

  /// Switches the password fields between hidden and readable text.
  void _onPasswordVisibilityToggled(
    RegistrationPasswordVisibilityToggled event,
    Emitter<DriverRegistrationState> emit,
  ) {
    emit(state.copyWith(passwordVisible: !state.passwordVisible));
  }

  /// Turns on the error messages of step 1 after "Continue" is tapped.
  void _onStep1Continued(
    RegistrationStep1Continued event,
    Emitter<DriverRegistrationState> emit,
  ) {
    emit(state.copyWith(showStep1Errors: true));
  }

  /// Stores the vehicle type the driver tapped on step 2.
  void _onVehicleTypeSelected(
    RegistrationVehicleTypeSelected event,
    Emitter<DriverRegistrationState> emit,
  ) {
    emit(state.copyWith(vehicleType: event.vehicleType));
  }

  /// Finishes the registration. It shows step 2's errors, stops if any
  /// answer is wrong, then creates the account and saves the vehicle.
  /// The status becomes success, or failure with a readable message.
  Future<void> _onSubmitted(
    RegistrationSubmitted event,
    Emitter<DriverRegistrationState> emit,
  ) async {
    // Extra taps are ignored while a save is already running.
    if (state.status == DriverRegistrationStatus.submitting) {
      return;
    }

    emit(state.copyWith(showStep2Errors: true));
    if (!state.isStep1Valid || !state.isStep2Valid) {
      return;
    }

    emit(state.copyWith(status: DriverRegistrationStatus.submitting));
    try {
      if (!_accountCreated) {
        await _createDriverAccount();
        _accountCreated = true;
      }
      await _vehicleRepository.addVehicle(
        vehicleType: state.vehicleType!,
        plateNumber: formatRwandaPlate(state.plateNumber),
      );
      emit(state.copyWith(status: DriverRegistrationStatus.success));
    } catch (error) {
      emit(
        state.copyWith(
          status: DriverRegistrationStatus.failure,
          error: _readable(error),
        ),
      );
    }
  }

  /// Creates the driver's login account and their 'users' document
  /// through AuthRepository, using the answers from step 1.
  Future<void> _createDriverAccount() async {
    await _authRepository.register(
      fullName: state.fullName.trim(),
      email: state.email.trim(),
      phone: state.normalizedPhone,
      password: state.password,
      role: UserRoles.driver,
      district: state.baseDistrict,
    );
  }

  /// Removes the "Exception: " prefix so the driver sees a clean sentence.
  String _readable(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
