// Owner: Member 2
// Screen: Settings (theme, notifications, default district) (StatelessWidget, template: ARCHITECTURE.md Part 5)
// Owner: Member 2
// Screen: Settings (theme, notifications, default district) (StatelessWidget, template: ARCHITECTURE.md Part 5)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/domain/repositories/settings_repository.dart';
import 'package:imuka_kigali/presentation/screens/settings/settings_bloc.dart';

/// The settings screen: theme, notifications and default district.
/// All three are saved on the phone and restored when the app reopens.
class SettingsScreen extends StatelessWidget {
  /// Creates the screen. It reads everything from the global SettingsBloc.
  const SettingsScreen({super.key});

  /// Shows [message] in a snackbar at the bottom of the screen.
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Draws the three groups of settings in a scrolling list, so nothing
  /// overflows in landscape. A failure in the bloc shows a snackbar.
  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsBloc, SettingsState>(
      listenWhen: (previous, current) =>
      current.status == SettingsStatus.failure,
      listener: (context, state) =>
          _showError(context, state.error ?? 'Something went wrong.'),
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: SafeArea(
          child: BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) {
              final bloc = context.read<SettingsBloc>();
              return ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                children: [
                  const _SectionTitle('Appearance'),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('System'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                        ),
                      ],
                      selected: {state.themeMode},
                      onSelectionChanged: (selection) =>
                          bloc.add(ThemeModeChanged(selection.first)),
                    ),
                  ),
                  const _SectionTitle('Notifications'),
                  SwitchListTile(
                    title: const Text('Move alerts'),
                    subtitle: const Text('Get updates about your moves'),
                    value: state.notificationsEnabled,
                    onChanged: (enabled) =>
                        bloc.add(NotificationsToggled(enabled)),
                  ),
                  const _SectionTitle('Location'),
                  ListTile(
                    title: const Text('Default district'),
                    subtitle: const Text('Your usual area in Kigali'),
                    trailing: DropdownButton<String>(
                      value: state.defaultDistrict,
                      underline: const SizedBox.shrink(),
                      items: [
                        for (final district in kigaliDistricts)
                          DropdownMenuItem(
                            value: district,
                            child: Text(district),
                          ),
                      ],
                      onChanged: (district) {
                        if (district != null) {
                          bloc.add(DefaultDistrictChanged(district));
                        }
                      },
                    ),
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

/// A small coloured heading above each group of settings.
class _SectionTitle extends StatelessWidget {
  /// Creates the heading with its text.
  const _SectionTitle(this.text);

  final String text;

  /// Draws the text in the theme's primary colour with space around it.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
