// Owner: Member 1
// Screen: Login. Email + password, plus "Forgot password?".
// This screen does not decide where the user goes after logging in.
// The router does that (clients and drivers have different home screens).
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/widgets.dart';
import 'auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// A StatefulWidget only so it can keep the form key and text controllers
// alive between rebuilds (allowed in team rules). It never rebuilds itself:
// loading, errors and messages all come from AuthBloc.
class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _logIn() {
    // If a field is wrong, validate() shows its error and we stop here.
    if (!_formKey.currentState!.validate()) {
      return;
    }
    context.read<AuthBloc>().add(
      LoginSubmitted(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  void _forgotPassword() {
    // The reset link is sent to the email typed above, so only that
    // field needs to be correct (the password can be empty).
    final emailError = Validators.email(_emailController.text);
    if (emailError != null) {
      showAppSnackBar(
        context,
        'Type your email above first, then tap "Forgot password?".',
        type: SnackBarType.error,
      );
      return;
    }
    context.read<AuthBloc>().add(
      PasswordResetRequested(_emailController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;

    // The app opens on this page while it checks for a saved session.
    // Showing the form then would flash it for users who are already
    // signed in, so a spinner is shown until we know who the user is.
    final checkingSession = context.select(
      (AuthBloc bloc) => bloc.state.status == AuthStatus.unknown,
    );
    if (checkingSession) {
      return const Scaffold(body: LoadingView());
    }

    return BlocListener<AuthBloc, AuthState>(
      // AuthState drops error and message on the next state, so each one
      // reaches this listener once and the snackbar never repeats.
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
          // Scrolling keeps the form usable in landscape and when the
          // keyboard covers the bottom half of the screen.
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _BrandHeader(),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Welcome Back', style: textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Log in to track your relocation or manage your driver '
                    'dispatch earnings.',
                    style: textTheme.bodyLarge?.copyWith(color: mutedColor),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                        AppTextField(
                          label: 'Password',
                          hint: 'Enter your confidential password',
                          prefixIcon: Icons.lock_outline,
                          controller: _passwordController,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          // Only "not empty" here. The 8-character rule belongs
                          // on sign-up; checking it at login would only hide
                          // the real "wrong password" message from Firebase.
                          validator: (value) =>
                              Validators.required(value, field: 'Password'),
                          onFieldSubmitted: (_) => _logIn(),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AppButton.text(
                            label: 'Forgot password?',
                            onPressed: _forgotPassword,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        // Only this button rebuilds when loading starts or stops.
                        BlocBuilder<AuthBloc, AuthState>(
                          buildWhen: (previous, current) =>
                              previous.isLoading != current.isLoading,
                          builder: (context, state) => AppButton(
                            label: 'Log In to Imuka Kigali',
                            trailingIcon: Icons.arrow_forward,
                            isLoading: state.isLoading,
                            onPressed: _logIn,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _LinkRow(
                    question: 'New to Imuka Kigali?',
                    linkLabel: 'Create account',
                    onPressed: () => context.push(AppRoutes.createAccount),
                  ),
                  _LinkRow(
                    question: 'Have a vehicle?',
                    linkLabel: 'Become a driver partner',
                    onPressed: () => context.push(AppRoutes.driverPartner),
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

/// The app icon and name at the top of the screen, as in the Figma design.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        // There is no logo image in the project yet, so a truck icon on a
        // dark rounded square stands in for it.
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.inverseSurface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Icon(
              Icons.local_shipping_outlined,
              color: scheme.onInverseSurface,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text('Imuka Kigali', style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

/// A short question followed by a text link, e.g. "New here? Create account".
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.question,
    required this.linkLabel,
    required this.onPressed,
  });

  final String question;
  final String linkLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // Wrap instead of Row, so on a narrow phone the link moves to the next
    // line instead of overflowing.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(question),
        AppButton.text(label: linkLabel, onPressed: onPressed),
      ],
    );
  }
}
