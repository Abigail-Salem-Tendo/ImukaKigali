

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../domain/entities/vehicle.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/vehicle_repository.dart';
import 'driver_registration_bloc.dart';
import 'registration_widgets.dart';

class DriverRegistrationStep1Screen extends StatelessWidget {
  const DriverRegistrationStep1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    // This screen CREATES the registration bloc. Step 2 receives the same
    // bloc, so everything typed here is still there on step 2.
    return BlocProvider(
      create: (ctx) => DriverRegistrationBloc(
        authRepository: ctx.read<AuthRepository>(),
        vehicleRepository: ctx.read<VehicleRepository>(),
      ),
      child: const _Step1View(),
    );
  }
}

class _Step1View extends StatelessWidget {
  const _Step1View();

  void _onContinuePressed(BuildContext context) {
    final bloc = context.read<DriverRegistrationBloc>();
    // From now on, show the red error messages under wrong fields.
    bloc.add(const RegistrationStep1Continued());

    // The bloc has been checking every answer while the driver typed.
    if (bloc.state.isStep1Valid) {
      // Hand the SAME bloc to step 2 (app_router.dart reads it from "extra").
      context.push(AppRoutes.driverRegister2, extra: bloc);
    } else {
      showAppSnackBar(context, 'Please fix the highlighted fields.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const RegistrationAppBarTitle()),
      body: SafeArea(
        // BlocBuilder DRAWS the screen again whenever the state changes.
        child: BlocBuilder<DriverRegistrationBloc, DriverRegistrationState>(
          builder: (context, state) {
            final bloc = context.read<DriverRegistrationBloc>();

            // Errors only appear after the driver taps Continue once.
            String? errorIf(String? error) =>
                state.showStep1Errors ? error : null;
            final hubsError = errorIf(state.hubsError);

            // ListView scrolls, so nothing overflows in landscape
            // or on small phones.
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const RegistrationStepCard(
                  step: 1,
                  title: 'Personal & Location',
                  progress: 0.5,
                  activeLabel: 'Active: Step 1',
                  nextLabel: 'Next: Vehicle & Compliance',
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Enter your personal contact info and primary operating '
                      'sectors across Kigali to get matched with nearby '
                      'relocations.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // ---------------- Personal information ----------------
                FormSection(
                  icon: Icons.badge_outlined,
                  title: 'Personal information',
                  children: [
                    const FieldLabel('Full Legal Name', isRequired: true),
                    TextFormField(
                      initialValue: state.fullName,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: 'e.g. Jean-Claude Mugisha',
                        prefixIcon: const Icon(Icons.person_outline),
                        errorText: errorIf(state.fullNameError),
                      ),
                      onChanged: (value) => bloc.add(
                        RegistrationFieldChanged(
                          RegistrationField.fullName,
                          value,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // ---------------- Contact & MoMo Payout ----------------
                FormSection(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Contact & MoMo Payout',
                  children: [
                    const FieldLabel(
                      'Rwanda Phone Number (MoMo Payouts)',
                      isRequired: true,
                    ),
                    TextFormField(
                      initialValue: state.phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: '788 123 456',
                        prefixIcon: const _CountryCodePrefix(),
                        errorText: errorIf(state.phoneError),
                      ),
                      onChanged: (value) => bloc.add(
                        RegistrationFieldChanged(RegistrationField.phone, value),
                      ),
                    ),
                    const FieldLabel('Email Address', isRequired: true),
                    TextFormField(
                      initialValue: state.email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: InputDecoration(
                        hintText: 'e.g. jeanclaude.mugisha@gmail.com',
                        prefixIcon: const Icon(Icons.mail_outline),
                        errorText: errorIf(state.emailError),
                      ),
                      onChanged: (value) => bloc.add(
                        RegistrationFieldChanged(RegistrationField.email, value),
                      ),
                    ),
                    const FieldLabel('Secure Password', isRequired: true),
                    TextFormField(
                      initialValue: state.password,
                      obscureText: !state.passwordVisible,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: 'Min. 8 characters',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: _PasswordEyeButton(
                          visible: state.passwordVisible,
                          onPressed: () => bloc.add(
                            const RegistrationPasswordVisibilityToggled(),
                          ),
                        ),
                        errorText: errorIf(state.passwordError),
                      ),
                      onChanged: (value) => bloc.add(
                        RegistrationFieldChanged(
                          RegistrationField.password,
                          value,
                        ),
                      ),
                    ),
                    const FieldLabel('Confirm password', isRequired: true),
                    TextFormField(
                      initialValue: state.confirmPassword,
                      obscureText: !state.passwordVisible,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: 'Min. 8 characters',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: _PasswordEyeButton(
                          visible: state.passwordVisible,
                          onPressed: () => bloc.add(
                            const RegistrationPasswordVisibilityToggled(),
                          ),
                        ),
                        errorText: errorIf(state.confirmPasswordError),
                      ),
                      onChanged: (value) => bloc.add(
                        RegistrationFieldChanged(
                          RegistrationField.confirmPassword,
                          value,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // ---------------- Base Location in Kigali ----------------
                FormSection(
                  icon: Icons.explore_outlined,
                  title: 'Base Location in Kigali',
                  children: [
                    Text(
                      'Select where you usually park or start your shifts to '
                          'receive priority nearby move dispatches.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Active Operating Hubs (Select 2+)',
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                        Text(
                          '${state.operatingHubs.length} Selected',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final hub in kigaliHubDistricts.keys)
                          FilterChip(
                            label: Text(hub),
                            selected: state.operatingHubs.contains(hub),
                            onSelected: (_) =>
                                bloc.add(RegistrationHubToggled(hub)),
                          ),
                      ],
                    ),
                    if (hubsError != null) GroupErrorText(hubsError),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                ArrowButton(
                  text: 'Continue to Vehicle Details',
                  onPressed: () => _onContinuePressed(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The "+250" at the start of the phone field. Using prefixIcon (not
/// prefixText) keeps it visible even before the driver starts typing.
class _CountryCodePrefix extends StatelessWidget {
  const _CountryCodePrefix();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Text('+250', style: theme.textTheme.titleSmall),
    );
  }
}

/// The eye icon that shows or hides the password.
class _PasswordEyeButton extends StatelessWidget {
  const _PasswordEyeButton({required this.visible, required this.onPressed});

  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: visible ? 'Hide password' : 'Show password',
      icon: Icon(
        visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
      onPressed: onPressed,
    );
  }
}
