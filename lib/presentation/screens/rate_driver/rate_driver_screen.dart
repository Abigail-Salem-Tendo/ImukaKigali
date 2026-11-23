// Owner: Member 5
// Screen: the client rates the driver after the deal (stars and a comment).
// Route: AppRoutes.rate.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/core/widgets/widgets.dart';
import 'package:imuka_kigali/domain/repositories/rating_repository.dart';
import 'package:imuka_kigali/domain/repositories/request_repository.dart';
import 'package:imuka_kigali/presentation/screens/login/auth_bloc.dart';
import 'package:imuka_kigali/presentation/screens/rate_driver/rating_bloc.dart';
import 'package:imuka_kigali/presentation/screens/rate_driver/star_picker.dart';

/// Creates its own bloc. The viewer is the signed-in user, which is how the
/// bloc knows if this is the client who may rate.
class RateDriverScreen extends StatelessWidget {
  const RateDriverScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    final viewerId = context.read<AuthBloc>().state.user?.uid ?? '';
    return BlocProvider(
      create: (context) => RatingBloc(
        context.read<RatingRepository>(),
        context.read<RequestRepository>(),
        requestId,
        viewerId,
      )..add(const RatingStarted()),
      child: const _RateDriverView(),
    );
  }
}

class _RateDriverView extends StatelessWidget {
  const _RateDriverView();

  static String _outcomeMessage(RatingOutcome outcome) => switch (outcome) {
    RatingOutcome.created => 'Thanks for rating your driver',
    RatingOutcome.updated => 'Your rating was updated',
    RatingOutcome.deleted => 'Your rating was removed',
  };

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<RatingBloc, RatingState>(
          listenWhen: (previous, current) =>
              current.error != null && previous.error != current.error,
          listener: (context, state) =>
              showAppSnackBar(context, state.error!, type: SnackBarType.error),
        ),
        BlocListener<RatingBloc, RatingState>(
          listenWhen: (previous, current) =>
              current.outcome != null && previous.outcome != current.outcome,
          listener: (context, state) => showAppSnackBar(
            context,
            _outcomeMessage(state.outcome!),
            type: SnackBarType.success,
          ),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(title: const Text('Rate your driver')),
        body: SafeArea(
          child: BlocBuilder<RatingBloc, RatingState>(
            builder: (context, state) {
              final request = state.request;
              if (request == null) {
                return state.status == RatingStatus.failure
                    ? EmptyState.error(
                        message: state.error,
                        onRetry: () => context.read<RatingBloc>().add(
                          const RatingStarted(),
                        ),
                      )
                    : const LoadingView(message: 'Loading your delivery');
              }
              if (!state.canRate) {
                return EmptyState(
                  icon: Icons.star_outline,
                  title: state.isClient
                      ? 'You can rate after paying'
                      : 'Only the client rates the driver',
                  message: state.isClient
                      ? 'Finish the handshake and payment first.'
                      : null,
                  actionLabel: 'Back',
                  onAction: () => context.go(
                    state.isClient
                        ? AppRoutes.deliveryPath(request.id)
                        : AppRoutes.driverJobs,
                  ),
                );
              }
              return _RatingForm(state: state);
            },
          ),
        ),
      ),
    );
  }
}

class _RatingForm extends StatelessWidget {
  const _RatingForm({required this.state});

  final RatingState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bloc = context.read<RatingBloc>();
    final request = state.request!;
    final hasRating = state.existing != null;

    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        Text(
          'How was your delivery?',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${request.pickupLocation} → ${request.dropoffLocation}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        StarPicker(
          stars: state.stars,
          onSelected: (stars) => bloc.add(StarsSelected(stars)),
        ),
        const SizedBox(height: AppSpacing.lg),
        // A new key rebuilds the field when a rating is saved or removed.
        AppTextField(
          key: ValueKey(state.existing?.id ?? 'new'),
          label: 'Comment',
          hint: 'Tell us how it went',
          isOptional: true,
          maxLines: 4,
          initialValue: state.comment,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (text) => bloc.add(CommentChanged(text)),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: hasRating ? 'Update rating' : 'Submit rating',
          icon: Icons.star,
          isLoading: state.saving,
          onPressed: state.canSubmit
              ? () => bloc.add(const RatingSubmitted())
              : null,
        ),
        if (hasRating) ...[
          const SizedBox(height: AppSpacing.sm),
          AppButton.danger(
            label: 'Remove rating',
            icon: Icons.delete_outline,
            onPressed: state.saving ? null : () => _confirmDelete(context),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        AppButton.text(
          label: hasRating ? 'Done' : 'Skip for now',
          onPressed: () => context.go(AppRoutes.whereFromTo),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bloc = context.read<RatingBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove your rating?'),
        content: const Text('You can rate this driver again afterwards.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) bloc.add(const RatingDeleted());
  }
}
