import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/core/widgets/app_snack_bar.dart';
import 'package:imuka_kigali/domain/entities/vehicle_class.dart';
import 'package:imuka_kigali/domain/repositories/auth_repository.dart';
import 'package:imuka_kigali/domain/repositories/vehicle_repository.dart';
import 'package:imuka_kigali/presentation/screens/driver_registration_step1/driver_registration_bloc.dart';
import 'package:imuka_kigali/presentation/screens/driver_registration_step1/registration_widget.dart';

/// Driver registration, step 1: personal details, contact and base location.
class DriverRegistrationStep1Screen extends StatelessWidget {
  /// Creates the screen. It needs no data.
  const DriverRegistrationStep1Screen({super.key});

  /// Creates the DriverRegistrationBloc and puts the step 1 view under it.
  /// Step 2 later receives this same bloc, so the answers are kept.
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => DriverRegistrationBloc(
        authRepository: ctx.read<AuthRepository>(),
        vehicleRepository: ctx.read<VehicleRepository>(),
      ),
      child: const _Step1View(),
    );
  }
}

/// The visible part of step 1.
class _Step1View extends StatelessWidget {
  /// Creates the view. It reads everything from the bloc.
  const _Step1View();

  /// Runs when "Continue" is tapped. It turns on the error messages, then
  /// opens step 2 if every answer is valid, or shows a snackbar if not.
  void _onContinuePressed(BuildContext context) {
    final bloc = context.read<DriverRegistrationBloc>();
    bloc.add(const RegistrationStep1Continued());

    if (bloc.state.isStep1Valid) {
      // The bloc travels to step 2 through the route's "extra" value.
      context.push(AppRoutes.driverRegister2, extra: bloc);
    } else {
      showAppSnackBar(context, 'Please fix the highlighted fields.');
    }
  }

  /// Draws the whole form in a scrolling list, so it fits small phones
  /// and landscape. It redraws whenever the bloc's state changes.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const RegistrationAppBarTitle()),
      body: SafeArea(
        child: BlocBuilder<DriverRegistrationBloc, DriverRegistrationState>(
          builder: (context, state) {
            final bloc = context.read<DriverRegistrationBloc>();

            // Returns the error only after "Continue" was tapped once.
            String? errorIf(String? error) =>
                state.showStep1Errors ? error : null;
            final hubsError = errorIf(state.hubsError);

            return ListView(
              padding: AppSpacing.screenPadding,
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
                        RegistrationFieldChanged(
                          RegistrationField.phone,
                          value,
                        ),
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
                        RegistrationFieldChanged(
                          RegistrationField.email,
                          value,
                        ),
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

/// The "+250" shown at the start of the phone field.
class _CountryCodePrefix extends StatelessWidget {
  /// Creates the prefix. It needs no data.
  const _CountryCodePrefix();

  /// Draws "+250" with space on both sides.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Text('+250', style: theme.textTheme.titleSmall),
    );
  }
}

/// The eye icon that shows or hides a password.
class _PasswordEyeButton extends StatelessWidget {
  /// Creates the button. [visible] says whether the password shows now.
  const _PasswordEyeButton({required this.visible, required this.onPressed});

  final bool visible;
  final VoidCallback onPressed;

  /// Draws an open eye when the password shows, or a crossed eye when hidden.
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
