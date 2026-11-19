// Owner: Member 1
// Screen: Create account, for clients ("movers"). Drivers sign up through
// the driver partner screens instead.
// After a successful sign-up the router moves the new client on by itself
// (see core/router/auth_redirect.dart), so this screen never navigates there.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/widgets.dart';
import '../login/auth_bloc.dart';

/// The three Kigali districts, with a few well-known areas in each so the
/// user can recognise where they live.
const _districts = {
  'Gasabo': 'Kimihurura / Kacyiru',
  'Kicukiro': 'Niboye / Gahanga',
  'Nyarugenge': 'Kiyovu / Nyamirambo',
};

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

// Stateful only to keep the form key and text controllers (team rule 2).
class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  // The district field below fills this in. It is a plain variable, not
  // screen state: nothing on screen is drawn from it.
  String? _district;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // The field already shows "+250", so the user only types the rest
  // (788 123 456). We save the full number, the same way driver
  // registration does: "+250788123456".
  String _fullPhone() {
    return '+250${Validators.normalizePhone(_phoneController.text)}';
  }

  void _createAccount() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    context.read<AuthBloc>().add(
      RegisterSubmitted(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _fullPhone(),
        password: _passwordController.text,
        role: UserRoles.client,
        district: _district!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => current.error != null,
      listener: (context, state) {
        showAppSnackBar(context, state.error!, type: SnackBarType.error);
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Back to login',
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.go(AppRoutes.login),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const BrandHeader(subtitle: 'Residential Mover'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Text.rich lets one word ("Mover") have its own colour.
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Create Your '),
                        TextSpan(
                          text: 'Mover',
                          style: TextStyle(color: scheme.primary),
                        ),
                        const TextSpan(text: ' Account'),
                      ],
                    ),
                    style: textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Book vetted trucks and move across Kigali with no stress '
                    'and upfront pricing.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          label: 'Full Name',
                          hint: 'e.g. Diane Uwase',
                          prefixIcon: Icons.person_outline,
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          validator: (value) =>
                              Validators.required(value, field: 'Full name'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: 'Mobile Number',
                          hint: '788 000 000',
                          prefixText: '+250 ',
                          helperText:
                              'Used for mover verification and MoMo payments.',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          validator: (_) => Validators.phone(_fullPhone()),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Not in the Figma frame, but we log in with email.
                        AppTextField(
                          label: 'Email',
                          hint: 'Enter your email',
                          prefixIcon: Icons.mail_outline,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          validator: Validators.email,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _DistrictField(
                          onChanged: (district) => _district = district,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: 'Secure Password',
                          hint: 'Min. 8 characters',
                          prefixIcon: Icons.lock_outline,
                          controller: _passwordController,
                          isPassword: true,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          validator: Validators.password,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: 'Confirm password',
                          hint: 'Min. 8 characters',
                          prefixIcon: Icons.lock_outline,
                          controller: _confirmController,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          validator: (value) => Validators.confirmPassword(
                            value,
                            _passwordController.text,
                          ),
                          onFieldSubmitted: (_) => _createAccount(),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        BlocBuilder<AuthBloc, AuthState>(
                          buildWhen: (previous, current) =>
                              previous.isLoading != current.isLoading,
                          builder: (context, state) => AppButton(
                            label: 'Create Mover Account',
                            trailingIcon: Icons.arrow_forward,
                            isLoading: state.isLoading,
                            onPressed: _createAccount,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Already have an account?'),
                      AppButton.text(
                        label: 'Log In',
                        onPressed: () => context.go(AppRoutes.login),
                      ),
                    ],
                  ),
                  // For drivers who tapped "Create account" by mistake:
                  // this page only makes client accounts.
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Have a vehicle?'),
                      AppButton.text(
                        label: 'Become a driver partner',
                        onPressed: () => context.go(AppRoutes.driverPartner),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The three district cards. A FormField keeps the chosen district and its
/// error message itself, so it is checked by Form.validate() together with
/// the text fields, and the screen doesn't have to redraw anything.
class _DistrictField extends StatelessWidget {
  const _DistrictField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FormField<String>(
      validator: (value) => value == null ? 'Choose your district' : null,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your District', style: textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (final district in _districts.keys) ...[
                if (district != _districts.keys.first)
                  const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppCard(
                    highlighted: field.value == district,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    onTap: () {
                      field.didChange(district);
                      onChanged(district);
                    },
                    child: Column(
                      children: [
                        Text(district, style: textTheme.labelLarge),
                        Text(
                          _districts[district]!,
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (field.hasError)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                field.errorText!,
                style: textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
