

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../domain/entities/vehicle.dart';
import '../driver_registration_step1/driver_registration_bloc.dart';
import '../driver_registration_step1/registration_widgets.dart';
import '../login/auth_bloc.dart';
import 'vehicle_type_card.dart';

class DriverRegistrationStep2Screen extends StatelessWidget {
  const DriverRegistrationStep2Screen({super.key, required this.bloc});

  /// The bloc that step 1 created, passed in by app_router.dart.
  final DriverRegistrationBloc bloc;

  @override
  Widget build(BuildContext context) {
    // BlocProvider.value shares a bloc that ALREADY exists and does not close
    // it. Step 1 owns it and closes it when the registration flow ends.
    return BlocProvider.value(value: bloc, child: const _Step2View());
  }
}

class _Step2View extends StatelessWidget {
  const _Step2View();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // BlocListener REACTS to changes (snackbars, moving to another screen).
    return BlocListener<DriverRegistrationBloc, DriverRegistrationState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == DriverRegistrationStatus.failure) {
          showAppSnackBar(
            context,
            state.error ?? 'Registration failed. Please try again.',
          );
        }
        if (state.status == DriverRegistrationStatus.success) {
          // Ask the global AuthBloc (Member 1) to load the new account...
          context.read<AuthBloc>().add(const AuthCheckRequested());
          showAppSnackBar(context, 'Registration complete. Welcome aboard!');
          // ...then open the driver home. go() also removes both
          // registration screens, so "back" will not return to them.
          context.go(AppRoutes.driverHome);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const RegistrationAppBarTitle()),
        body: SafeArea(
          child: BlocBuilder<DriverRegistrationBloc, DriverRegistrationState>(
            builder: (context, state) {
              final bloc = context.read<DriverRegistrationBloc>();
              final vehicleTypeError =
              state.showStep2Errors ? state.vehicleTypeError : null;
              final plateError =
              state.showStep2Errors ? state.plateNumberError : null;

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
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
                          text: 'Select your vehicle class. Kigali vehicle '
                              'regulations strictly differentiate ',
                        ),
                        TextSpan(
                          text: 'Tricycles (Moto Plate Series)',
                          style: TextStyle(color: colors.primary),
                        ),
                        const TextSpan(
                          text: ' from standard Car & Truck automotive '
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

                  // One card per vehicle class.
                  for (final type in VehicleType.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: VehicleTypeCard(
                        vehicleType: type,
                        selected: state.vehicleType == type,
                        onTap: () =>
                            bloc.add(RegistrationVehicleTypeSelected(type)),
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
                          hintText: 'e.g. RAD 428 E',
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
