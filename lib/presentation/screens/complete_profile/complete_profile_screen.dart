// Owner: Member 1
// Screen: Complete your profile. Shown once, after someone signs in with
// Google for the first time. Google gives us their email, but not the
// phone, district and role every user needs, so this screen asks for them.
// When the profile is saved the router moves them on by itself (see
// core/router/auth_redirect.dart), so this screen never navigates there.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/firestore_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/widgets.dart';
import '../create_account/district_field.dart';
import '../login/auth_bloc.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

// Stateful only to keep the form key and text controllers (team rule 2).
class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Filled in by the card fields below. Plain variables, not screen state:
  // nothing on screen is drawn from them.
  String? _district;
  String? _role;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    context.read<AuthBloc>().add(
      ProfileCompleted(
        fullName: _nameController.text.trim(),
        phone: Validators.fullRwandanPhone(_phoneController.text),
        role: _role!,
        district: _district!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;

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
                  const BrandHeader(),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Complete your profile',
                    style: textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'One last step. Movers and drivers use these details to '
                    'reach each other.',
                    style: textTheme.bodyLarge?.copyWith(color: mutedColor),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _RoleField(onChanged: (role) => _role = role),
                        const SizedBox(height: AppSpacing.md),
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
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          validator: (_) => Validators.phone(
                            Validators.fullRwandanPhone(_phoneController.text),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        DistrictField(
                          onChanged: (district) => _district = district,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        BlocBuilder<AuthBloc, AuthState>(
                          buildWhen: (previous, current) =>
                              previous.isLoading != current.isLoading,
                          builder: (context, state) => AppButton(
                            label: 'Continue',
                            trailingIcon: Icons.arrow_forward,
                            isLoading: state.isLoading,
                            onPressed: _continue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // For someone who picked the wrong Google account: signing
                  // out sends them back to the login screen.
                  AppButton.text(
                    label: 'Use a different account',
                    onPressed: () =>
                        context.read<AuthBloc>().add(const LogoutRequested()),
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

/// Two cards: moving house (client) or driving (driver). Chosen first,
/// because it decides which side of the app the user lands on.
/// A FormField, like DistrictField, so Form.validate() checks it too.
class _RoleField extends StatelessWidget {
  const _RoleField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FormField<String>(
      validator: (value) => value == null ? 'Choose how you use Imuka' : null,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('I want to', style: textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _RoleCard(
                  icon: Icons.home_outlined,
                  title: 'Move house',
                  caption: 'Book a mover',
                  selected: field.value == UserRoles.client,
                  onTap: () {
                    field.didChange(UserRoles.client);
                    onChanged(UserRoles.client);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _RoleCard(
                  icon: Icons.local_shipping_outlined,
                  title: 'Drive',
                  caption: 'Earn with my vehicle',
                  selected: field.value == UserRoles.driver,
                  onTap: () {
                    field.didChange(UserRoles.driver);
                    onChanged(UserRoles.driver);
                  },
                ),
              ),
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

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.caption,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String caption;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      highlighted: selected,
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          Text(title, style: textTheme.labelLarge),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
