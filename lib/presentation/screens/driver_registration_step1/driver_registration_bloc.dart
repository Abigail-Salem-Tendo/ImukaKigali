
// DriverRegistrationBloc is shared by step 1 and step 2:
// - it remembers what the driver typed on step 1 while they fill in step 2,
// - it checks every answer (the rules live in driver_registration_state.dart),
// - on "Complete Registration" it creates the account and saves the vehicle.

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/vehicle.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/vehicle_repository.dart';

part 'driver_registration_event.dart';
part 'driver_registration_state.dart';

class DriverRegistrationBloc
    extends Bloc<DriverRegistrationEvent, DriverRegistrationState> {
  DriverRegistrationBloc({
    required AuthRepository authRepository,
    required VehicleRepository vehicleRepository,
  })  : _authRepository = authRepository,
        _vehicleRepository = vehicleRepository,
        super(const DriverRegistrationState()) {
    // "When this event arrives, run this method."
    on<RegistrationFieldChanged>(_onFieldChanged);
    on<RegistrationHubToggled>(_onHubToggled);
    on<RegistrationPasswordVisibilityToggled>(_onPasswordVisibilityToggled);
    on<RegistrationStep1Continued>(_onStep1Continued);
    on<RegistrationVehicleTypeSelected>(_onVehicleTypeSelected);
    on<RegistrationSubmitted>(_onSubmitted);
  }

  // Member 1's repository creates the login account and the 'users' document.
  final AuthRepository _authRepository;
  final VehicleRepository _vehicleRepository;

  /// Becomes true once the account exists. If saving the vehicle then fails
  /// and the driver taps again, we must not try to create the account twice.
  bool _accountCreated = false;

  void _onFieldChanged(
      RegistrationFieldChanged event,
      Emitter<DriverRegistrationState> emit,
      ) {
    // The "switch" picks which value to update.
    emit(
      switch (event.field) {
        RegistrationField.fullName => state.copyWith(fullName: event.value),
        RegistrationField.phone => state.copyWith(phone: event.value),
        RegistrationField.email => state.copyWith(email: event.value),
        RegistrationField.password => state.copyWith(password: event.value),
        RegistrationField.confirmPassword =>
            state.copyWith(confirmPassword: event.value),
        RegistrationField.plateNumber =>
            state.copyWith(plateNumber: event.value),
      },
    );
  }

  void _onHubToggled(
      RegistrationHubToggled event,
      Emitter<DriverRegistrationState> emit,
      ) {
    // Make a NEW list. Changing the old list would not count as a new state.
    final hubs = [...state.operatingHubs];
    if (hubs.contains(event.hub)) {
      hubs.remove(event.hub);
    } else {
      hubs.add(event.hub);
    }
    emit(state.copyWith(operatingHubs: hubs));
  }

  void _onPasswordVisibilityToggled(
      RegistrationPasswordVisibilityToggled event,
      Emitter<DriverRegistrationState> emit,
      ) {
    emit(state.copyWith(passwordVisible: !state.passwordVisible));
  }

  void _onStep1Continued(
      RegistrationStep1Continued event,
      Emitter<DriverRegistrationState> emit,
      ) {
    emit(state.copyWith(showStep1Errors: true));
  }

  void _onVehicleTypeSelected(
      RegistrationVehicleTypeSelected event,
      Emitter<DriverRegistrationState> emit,
      ) {
    emit(state.copyWith(vehicleType: event.vehicleType));
  }

  Future<void> _onSubmitted(
      RegistrationSubmitted event,
      Emitter<DriverRegistrationState> emit,
      ) async {
    // Ignore extra taps while we are already saving.
    if (state.status == DriverRegistrationStatus.submitting) {
      return;
    }

    // Start showing step 2's error messages.
    emit(state.copyWith(showStep2Errors: true));

    // Stop here if anything is missing or wrong. The screen shows why.
    if (!state.isStep1Valid || !state.isStep2Valid) {
      return;
    }

    emit(state.copyWith(status: DriverRegistrationStatus.submitting));
    try {
      // 1. Create the login account and the 'users' document.
      if (!_accountCreated) {
        await _createDriverAccount();
        _accountCreated = true;
      }

      // 2. Save the vehicle. The repository links it to the new account.
      await _vehicleRepository.addVehicle(
        vehicleType: state.vehicleType!,
        plateNumber: formatRwandaPlate(state.plateNumber),
        operatingHubs: state.operatingHubs,
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

  /// The ONLY place that depends on Member 1's AuthRepository.register.
  /// If their method uses different parameter names, change them here.
  Future<void> _createDriverAccount() async {
    await _authRepository.register(
      fullName: state.fullName.trim(),
      email: state.email.trim(),
      phone: state.normalizedPhone,
      password: state.password,
      role: 'driver', // use Member 3's role constant if they made one
      district: state.baseDistrict,
    );
  }

  /// "Exception: No internet" -> "No internet"
  String _readable(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
