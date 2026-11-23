// Owner: Member 1
// Screen: Driver partner entry. Explains what a driver needs, then hands over
// to the driver registration steps (Member 2), which create the account.
// No form here, so it doesn't need AuthBloc.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';

class DriverPartnerRegistrationScreen extends StatelessWidget {
  const DriverPartnerRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
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
                  const BrandHeader(subtitle: 'Driver Partner'),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Drive & Earn with Imuka', style: textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Turn your tricycle, mini pickup, or truck into guaranteed '
                'daily income across Kigali.',
                style: textTheme.bodyLarge?.copyWith(color: mutedColor),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('What you need', style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    const _Requirement(
                      icon: Icons.badge_outlined,
                      text: 'Your full name and email',
                    ),
                    const _Requirement(
                      icon: Icons.phone_android,
                      text: 'A MoMo phone number for payments',
                    ),
                    const _Requirement(
                      icon: Icons.local_shipping_outlined,
                      text: 'Your vehicle and its Rwanda plate number',
                    ),
                    const _Requirement(
                      icon: Icons.place_outlined,
                      text: 'The Kigali hubs you work from',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // push, not go: the back arrow on step 1 then returns here.
              AppButton(
                label: 'Start registration',
                trailingIcon: Icons.arrow_forward,
                onPressed: () => context.push(AppRoutes.driverRegister1),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Already a partner?'),
                  AppButton.text(
                    label: 'Log In',
                    onPressed: () => context.go(AppRoutes.login),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One line of the "What you need" list: an icon and a short sentence.
class _Requirement extends StatelessWidget {
  const _Requirement({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppSpacing.iconMd,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          // Expanded lets a long sentence wrap instead of overflowing.
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
