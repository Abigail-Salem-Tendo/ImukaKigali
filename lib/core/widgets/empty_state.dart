// Owner: Member 1
// Shared widget: EmptyState. The "nothing here yet" and "something went wrong"
// cards from the Figma "Feedback, errors and loading" section.
//
//   EmptyState(
//     icon: Icons.work_outline,
//     title: 'No jobs yet',
//     message: 'New moves near you will show up here.',
//   )
//
//   EmptyState.error(
//     message: state.error,
//     onRetry: () => context.read<JobLogsBloc>().add(const JobLogsRequested()),
//   )
import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_button.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  }) : isError = false;

  /// Red-tinted version with a Retry button.
  const EmptyState.error({
    super.key,
    this.title = 'Something went wrong',
    this.message,
    this.icon = Icons.warning_amber_rounded,
    String retryLabel = 'Retry',
    VoidCallback? onRetry,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  }) : actionLabel = retryLabel,
       onAction = onRetry,
       isError = true;

  final String title;
  final String? message;
  final IconData icon;

  /// Button under the message. Hidden when [onAction] is null.
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = isError ? scheme.error : scheme.onSurfaceVariant;

    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isError
                ? scheme.error.withValues(alpha: 0.05)
                : scheme.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: isError
                ? Border.all(color: scheme.error.withValues(alpha: 0.2))
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: AppSpacing.iconMd, color: accent),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (onAction != null || onSecondaryAction != null) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (onAction != null && actionLabel != null)
                      isError
                          ? AppButton(
                              label: actionLabel!,
                              onPressed: onAction,
                              expand: false,
                            )
                          : AppButton.secondary(
                              label: actionLabel!,
                              onPressed: onAction,
                              expand: false,
                            ),
                    if (onSecondaryAction != null &&
                        secondaryActionLabel != null)
                      AppButton.secondary(
                        label: secondaryActionLabel!,
                        onPressed: onSecondaryAction,
                        expand: false,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
