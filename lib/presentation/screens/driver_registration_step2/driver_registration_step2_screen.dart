import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/core/widgets/app_snack_bar.dart';
import 'package:imuka_kigali/domain/entities/vehicle_class.dart';
import 'package:imuka_kigali/presentation/screens/driver_registration_step1/driver_registration_bloc.dart';
import 'package:imuka_kigali/presentation/screens/driver_registration_step1/registration_widget.dart';
import 'package:imuka_kigali/presentation/screens/driver_registration_step2/vehicle_type_card.dart';
import 'package:imuka_kigali/presentation/screens/login/auth_bloc.dart';

/// Driver registration, step 2: the vehicle type and the plate number.
class DriverRegistrationStep2Screen extends StatelessWidget {
  /// Creates the screen with the bloc that step 1 created.
  const DriverRegistrationStep2Screen({super.key, required this.bloc});

  final DriverRegistrationBloc bloc;

  /// Shares the existing bloc with the step 2 view. BlocProvider.value
  /// does not close the bloc, because step 1 owns it.
  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(value: bloc, child: const _Step2View());
  }
}

/// The visible part of step 2.
class _Step2View extends StatelessWidget {
  /// Creates the view. It reads everything from the bloc.
  const _Step2View();

  /// Reacts when the registration status changes. A failure shows the
  /// error in a snackbar. A success reloads the signed-in user and opens
  /// the driver home, removing the registration screens from the back
  /// stack.
  void _onStatusChanged(BuildContext context, DriverRegistrationState state) {
    if (state.status == DriverRegistrationStatus.failure) {
      showAppSnackBar(
        context,
        state.error ?? 'Registration failed. Please try again.',
      );
    }
    if (state.status == DriverRegistrationStatus.success) {
      context.read<AuthBloc>().add(const AuthCheckRequested());
      showAppSnackBar(context, 'Registration complete. Welcome aboard!');
      context.go(AppRoutes.driverHome);
    }
  }

  /// Draws the vehicle cards, the plate field and the finish button in a
  /// scrolling list. It redraws whenever the bloc's state changes.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return BlocListener<DriverRegistrationBloc, DriverRegistrationState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onStatusChanged,
      child: Scaffold(
        appBar: AppBar(title: const RegistrationAppBarTitle()),
        body: SafeArea(
          child: BlocBuilder<DriverRegistrationBloc, DriverRegistrationState>(
            builder: (context, state) {
              final bloc = context.read<DriverRegistrationBloc>();
              final vehicleTypeError = state.showStep2Errors
                  ? state.vehicleTypeError
                  : null;
              final plateError = state.showStep2Errors
                  ? state.plateNumberError
                  : null;
              final chosenType = state.vehicleType;
              final plateExample = chosenType == null
                  ? 'RAD 428 E'
                  : VehicleClasses.of(chosenType).plateExample;

              return ListView(
                padding: AppSpacing.screenPadding,
                children: [
                  const RegistrationStepCard(
                    step: 2,
                    title: 'Vehicle details',
                    progress: 1,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text.rich(
                    TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      children: [
                        const TextSpan(
                          text:
                              'Select your vehicle class. Kigali vehicle '
                              'regulations strictly differentiate ',
                        ),
                        TextSpan(
                          text: 'Tricycles (Moto Plate Series)',
                          style: TextStyle(color: colors.primary),
                        ),
                        const TextSpan(
                          text:
                              ' from standard Car & Truck automotive '
                              'plates.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Select Vehicle Category',
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      Text(
                        'TAP TO CHOOSE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final vehicleClass in VehicleClasses.all)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: VehicleTypeCard(
                        vehicleClass: vehicleClass,
                        selected: state.vehicleType == vehicleClass.type,
                        onTap: () => bloc.add(
                          RegistrationVehicleTypeSelected(vehicleClass.type),
                        ),
                      ),
                    ),
                  if (vehicleTypeError != null)
                    GroupErrorText(vehicleTypeError),
                  const SizedBox(height: AppSpacing.md),
                  FormSection(
                    title: 'Rwanda License Plate Number',
                    children: [
                      TextFormField(
                        initialValue: state.plateNumber,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.done,
                        autocorrect: false,
                        decoration: InputDecoration(
                          hintText: 'e.g. $plateExample',
                          prefixIcon: const Icon(
                            Icons.confirmation_number_outlined,
                          ),
                          errorText: plateError,
                        ),
                        onChanged: (value) => bloc.add(
                          RegistrationFieldChanged(
                            RegistrationField.plateNumber,
                            value,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ArrowButton(
                    text: 'Complete Registration',
                    isLoading:
                        state.status == DriverRegistrationStatus.submitting,
                    onPressed: () => bloc.add(const RegistrationSubmitted()),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
