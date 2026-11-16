import 'package:flutter/material.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';

/// The app bar title of the registration screens: a logo, "Imuka Kigali"
/// and "DRIVER PARTNER" under it.
class RegistrationAppBarTitle extends StatelessWidget {
  /// Creates the title. It needs no data.
  const RegistrationAppBarTitle({super.key});

  /// Draws the logo square with the two lines of text beside it.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(
            Icons.local_shipping,
            color: colors.onPrimary,
            size: AppSpacing.iconMd,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Imuka Kigali', style: theme.textTheme.titleSmall),
            Text(
              'DRIVER PARTNER',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.primary,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The progress card at the top of each step, for example
/// "1  Personal & Location   Step 1 of 2" with a progress bar under it.
class RegistrationStepCard extends StatelessWidget {
  /// Creates the card. [progress] goes from 0.0 (empty bar) to 1.0 (full).
  /// [activeLabel] and [nextLabel] are optional small texts under the bar.
  const RegistrationStepCard({
    super.key,
    required this.step,
    required this.title,
    required this.progress,
    this.activeLabel,
    this.nextLabel,
  });

  final int step;
  final String title;
  final double progress;
  final String? activeLabel;
  final String? nextLabel;

  /// Draws the step number, the title, the progress bar and, when both
  /// labels were given, the "active" and "next" texts.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final active = activeLabel;
    final next = nextLabel;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.cardInsets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: colors.primary,
                  child: Text(
                    '$step',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ),
                Text('Step $step of 2', style: theme.textTheme.labelMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.xs),
              child: LinearProgressIndicator(value: progress, minHeight: 6),
            ),
            if (active != null && next != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      active,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      next,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A card with an optional icon and a title that holds a group of fields,
/// for example "Personal information".
class FormSection extends StatelessWidget {
  /// Creates the section. [children] are the widgets placed under the title.
  const FormSection({
    super.key,
    required this.title,
    required this.children,
    this.icon,
  });

  final String title;
  final List<Widget> children;
  final IconData? icon;

  /// Draws the title row and then every child under it.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sectionIcon = icon;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.cardInsets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (sectionIcon != null) ...[
                  Icon(sectionIcon, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// The small label above a text field, for example "Full Legal Name *".
class FieldLabel extends StatelessWidget {
  /// Creates the label. [isRequired] adds a red star after the text.
  const FieldLabel(this.text, {super.key, this.isRequired = false});

  final String text;
  final bool isRequired;

  /// Draws the label text, followed by a red star when it is required.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
      child: Text.rich(
        TextSpan(
          text: text,
          style: theme.textTheme.labelLarge,
          children: [
            if (isRequired)
              TextSpan(
                text: ' *',
                style: TextStyle(color: theme.colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }
}

/// Small red text shown under a group, such as the hub chips, when the
/// group has a problem.
class GroupErrorText extends StatelessWidget {
  /// Creates the error text with the message to show.
  const GroupErrorText(this.message, {super.key});

  final String message;

  /// Draws the message in the theme's error colour.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}

/// A full-width button with an arrow after its text, for example
/// "Continue  →".
class ArrowButton extends StatelessWidget {
  /// Creates the button. While [isLoading] is true it shows a spinner and
  /// cannot be tapped.
  const ArrowButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  /// Draws the button with either its text and arrow, or a spinner.
  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox.square(
              dimension: AppSpacing.iconMd,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.arrow_forward),
              ],
            ),
    );
  }
}
