// Owner: Member 1
// Screen: Client home. Where a client lands after logging in: a greeting,
// a "Book a move" card that opens "Where to?", their moves (live), and an
// account menu with Settings and Log out.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/entities/move_request.dart';
import '../../../domain/repositories/request_repository.dart';
// Mufaro's money and date formats, so moves look the same on both sides.
import '../job_logs/job_log_format.dart';
import '../login/auth_bloc.dart';
import 'client_home_bloc.dart';

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => bloc.state.user);
    // The router only opens this page for a signed-in client, so user is
    // only null for a moment while logging out.
    if (user == null) {
      return const Scaffold(body: LoadingView());
    }
    final textTheme = Theme.of(context).textTheme;
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return BlocProvider(
      create: (context) =>
          ClientHomeBloc(context.read<RequestRepository>())
            ..add(ClientHomeStarted(user.uid)),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: const BrandHeader(),
          actions: [
            _AccountMenu(name: user.fullName, email: user.email),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Hi ${_firstName(user.fullName)} 👋',
                      style: textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Where are we moving today?',
                      style: textTheme.bodyLarge?.copyWith(color: mutedColor),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _BookMoveCard(),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Your moves', style: textTheme.titleMedium),
                  ],
                ),
              ),
              // The list takes the rest of the screen and scrolls by itself.
              Expanded(child: _MovesList(clientId: user.uid)),
            ],
          ),
        ),
      ),
    );
  }

  /// "Mitchell" from "Mitchell Barure". The whole name if it has one word.
  String _firstName(String fullName) => fullName.trim().split(' ').first;
}

/// The big card that starts a new request.
class _BookMoveCard extends StatelessWidget {
  const _BookMoveCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      highlighted: true,
      // push, not go: Back on "Where to?" returns here.
      onTap: () => context.push(AppRoutes.whereFromTo),
      child: Row(
        children: [
          CircleAvatar(
            radius: AppSpacing.lg,
            backgroundColor: scheme.primary,
            child: Icon(Icons.local_shipping, color: scheme.onPrimary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Book a move', style: textTheme.titleMedium),
                Text(
                  'Pick your areas and get a fixed price',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward, color: scheme.primary),
        ],
      ),
    );
  }
}

class _MovesList extends StatelessWidget {
  const _MovesList({required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientHomeBloc, ClientHomeState>(
      builder: (context, state) {
        if (state.status == ClientHomeStatus.loading) {
          return const LoadingView.skeleton();
        }
        if (state.status == ClientHomeStatus.failure) {
          return EmptyState.error(
            message: state.error,
            onRetry: () =>
                context.read<ClientHomeBloc>().add(ClientHomeStarted(clientId)),
          );
        }
        if (state.moves.isEmpty) {
          return const EmptyState(
            icon: Icons.local_shipping_outlined,
            title: 'No moves yet',
            message: 'Your moves show up here once you book one.',
          );
        }
        return ListView.separated(
          padding: AppSpacing.screenPadding,
          itemCount: state.moves.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) => _MoveCard(move: state.moves[index]),
        );
      },
    );
  }
}

class _MoveCard extends StatelessWidget {
  const _MoveCard({required this.move});

  final MoveRequest move;

  /// Where tapping the card goes: the page that follows that move now.
  /// Finished and cancelled moves have nowhere to go.
  String? _openPath() => switch (move.status) {
    RequestStatus.open => AppRoutes.findingDriverPath(move.id),
    RequestStatus.accepted => AppRoutes.driverContactPath(move.id),
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final path = _openPath();

    return AppCard(
      onTap: path == null ? null : () => context.push(path),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${move.pickupLocation} → ${move.dropoffLocation}',
                  style: textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusChip.request(move.status),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            move.itemDescription,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(color: mutedColor),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(formatRwf(move.proposedAmount), style: textTheme.labelLarge),
              const Spacer(),
              Text(
                jobTimeLabel(move.createdAt, DateTime.now()),
                style: textTheme.bodySmall?.copyWith(color: mutedColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The round icon at the top right. Shows who is signed in, and leads to
/// Settings and Log out.
class _AccountMenu extends StatelessWidget {
  const _AccountMenu({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      tooltip: 'Account',
      onSelected: (choice) {
        if (choice == 'settings') {
          context.push(AppRoutes.settings);
        } else if (choice == 'logout') {
          // The router sends them to the login page once they are out.
          context.read<AuthBloc>().add(const LogoutRequested());
        }
      },
      itemBuilder: (context) => [
        // Not tappable: it only says who is signed in.
        PopupMenuItem(
          enabled: false,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(name),
            subtitle: Text(email),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'settings',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.settings_outlined),
            title: Text('Settings'),
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout),
            title: Text('Log out'),
          ),
        ),
      ],
      child: CircleAvatar(
        backgroundColor: scheme.primaryContainer,
        child: Text(
          name.isEmpty ? '?' : name[0].toUpperCase(),
          style: TextStyle(color: scheme.onPrimaryContainer),
        ),
      ),
    );
  }
}
