// Owner: Member 1
// Shared widget: LoadingView. Shown while a bloc's status is loading.
//
//   if (state.status == XStatus.loading) return const LoadingView();
//   const LoadingView(message: 'Finding your driver...')
//   const LoadingView.skeleton()   // grey placeholder cards while a list loads
import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_card.dart';

class LoadingView extends StatelessWidget {
  /// A centred spinner with an optional message.
  const LoadingView({super.key, this.message})
    : _skeleton = false,
      itemCount = 0;

  /// Placeholder cards in the shape of the real content
  /// (the "loading screen" in the Figma design system). Use it for lists.
  const LoadingView.skeleton({super.key, this.itemCount = 3})
    : _skeleton = true,
      message = null;

  final String? message;

  /// Number of placeholder cards (skeleton only).
  final int itemCount;
  final bool _skeleton;

  @override
  Widget build(BuildContext context) {
    if (_skeleton) {
      return Semantics(
        label: 'Loading',
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: AppSpacing.screenPadding,
          child: Column(
            children: [
              for (var i = 0; i < itemCount; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                const _SkeletonCard(),
              ],
            ],
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Bar(widthFactor: 0.35, height: AppSpacing.md),
          SizedBox(height: AppSpacing.sm),
          _Bar(widthFactor: 0.7, height: AppSpacing.lg),
          SizedBox(height: AppSpacing.sm),
          _Bar(widthFactor: 0.5, height: AppSpacing.md),
          SizedBox(height: AppSpacing.md),
          _Bar(widthFactor: 1, height: AppSpacing.xxl),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _Bar(widthFactor: 1, height: AppSpacing.xl)),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: _Bar(widthFactor: 1, height: AppSpacing.xl)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.widthFactor, required this.height});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface
              .withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    );
  }
}
