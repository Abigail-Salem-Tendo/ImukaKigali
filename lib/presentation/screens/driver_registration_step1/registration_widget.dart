
// Small building blocks used by BOTH registration steps.


import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// The app bar title from the Figma: logo, "Imuka Kigali", "DRIVER PARTNER".
class RegistrationAppBarTitle extends StatelessWidget {
  const RegistrationAppBarTitle({super.key});

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
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: Icon(
            Icons.local_shipping,
            color: colors.onPrimary,
            size: AppSpacing.lg,
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

/// The progress card at the top: "1  Personal & Location   Step 1 of 2".
class RegistrationStepCard extends StatelessWidget {
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

  /// How full the bar is, from 0.0 (empty) to 1.0 (full).
  final double progress;

  final String? activeLabel;
  final String? nextLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // Copy the fields into local variables so Dart can see they are not null
    // inside the "if" below.
    final active = activeLabel;
    final next = nextLabel;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
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

/// A white card with an optional icon and a title, holding a group of fields.
/// Example: the "Personal information" and "Contact & MoMo Payout" cards.
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.title,
    required this.children,
    this.icon,
  });

  final String title;
  final List<Widget> children;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sectionIcon = icon;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
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

/// The small label above a text field, e.g. "Full Legal Name *".
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.isRequired = false});

  final String text;

  /// Adds a red "*" after the label.
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.xs,
      ),
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

/// Small red text under a group (like the hub chips) that has a problem.
class GroupErrorText extends StatelessWidget {
  const GroupErrorText(this.message, {super.key});

  final String message;

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

/// A big green button with an arrow at the end: "Continue  →".
/// While [isLoading] is true it shows a spinner and cannot be tapped twice.
class ArrowButton extends StatelessWidget {
  const ArrowButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(

        minimumSize: const Size.fromHeight(kMinInteractiveDimension),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox.square(
        dimension: AppSpacing.lg,
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
