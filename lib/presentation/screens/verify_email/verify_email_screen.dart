// Owner: Member 1
// Screen: "Check your inbox". A signed-in user whose email isn't verified
// yet is kept here by the router (see core/router/auth_redirect.dart).
// Once AuthBloc says the email is verified, the router moves them on by
// itself, so this screen never navigates.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../login/auth_bloc.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final email = context.select((AuthBloc bloc) => bloc.state.user?.email);

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          current.error != null || current.message != null,
      listener: (context, state) {
        if (state.error != null) {
          showAppSnackBar(context, state.error!, type: SnackBarType.error);
        }
        if (state.message != null) {
          showAppSnackBar(context, state.message!, type: SnackBarType.success);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BrandHeader(),
                const SizedBox(height: AppSpacing.xl),
                Icon(
                  Icons.mark_email_unread_outlined,
                  size: AppSpacing.xxl,
                  color: scheme.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Check your inbox',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'We sent a link to ${email ?? 'your email'}. Open it, then '
                  'come back and tap the button below.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  "Can't find it? Check your spam folder.",
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Both buttons wait while either request is running, so the
                // user can't fire several at once.
                BlocBuilder<AuthBloc, AuthState>(
                  buildWhen: (previous, current) =>
                      previous.isLoading != current.isLoading,
                  builder: (context, state) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppButton(
                        label: "I've verified my email",
                        isLoading: state.isLoading,
                        onPressed: () => context.read<AuthBloc>().add(
                          const EmailVerificationCheckRequested(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton.secondary(
                        label: 'Resend email',
                        onPressed: state.isLoading
                            ? null
                            : () => context.read<AuthBloc>().add(
                                const VerificationEmailResent(),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // A way out for someone who typed the wrong email: log out
                // and sign up again. The router then shows the login page.
                Center(
                  child: AppButton.text(
                    label: 'Use a different account',
                    onPressed: () =>
                        context.read<AuthBloc>().add(const LogoutRequested()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
