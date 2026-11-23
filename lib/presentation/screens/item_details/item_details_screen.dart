import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';

import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/core/widgets/widgets.dart';
import 'package:imuka_kigali/presentation/screens/login/auth_bloc.dart';
import 'package:imuka_kigali/domain/entities/vehicle_class.dart';
import 'package:imuka_kigali/presentation/screens/item_details/vehicle_option_tile.dart';
import 'package:imuka_kigali/presentation/screens/where_from_to/create_request_bloc.dart';

/// Uses the CreateRequestBloc provided by the ShellRoute in app_router.dart.
class ItemDetailsScreen extends StatelessWidget {
  const ItemDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<CreateRequestBloc, CreateRequestState>(
      // Only react when the status changes, not on every keystroke.
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == CreateRequestStatus.failure) {
          showAppSnackBar(
            context,
            state.error ?? 'Something went wrong',
            type: SnackBarType.error,
          );
        }
        if (state.status == CreateRequestStatus.success &&
            state.requestId != null) {
          context.go(AppRoutes.findingDriverPath(state.requestId!));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Item details')),
        body: SafeArea(
          child: BlocBuilder<CreateRequestBloc, CreateRequestState>(
            builder: (context, state) {
              final pickup = state.pickup;
              final dropoff = state.dropoff;
              // Opened without a route (hot restart, deep link): start over.
              if (pickup == null || dropoff == null) {
                return const _BackToStart();
              }
              final bloc = context.read<CreateRequestBloc>();
              final amount = state.proposedAmount;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${pickup.name} to ${dropoff.name}',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      initialValue: state.itemDescription,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'What are you moving?',
                      ),
                      onChanged: (v) => bloc.add(ItemDescriptionChanged(v)),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('Vehicle', style: theme.textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.sm),
                    for (final vehicleClass in VehicleClasses.all)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: VehicleOptionTile(
                          vehicleClass: vehicleClass,
                          selected: state.vehicleType == vehicleClass.type,
                          onTap: () =>
                              bloc.add(VehicleTypeSelected(vehicleClass.type)),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.cardPadding),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Price', style: theme.textTheme.titleMedium),
                            Text(
                              amount == null
                                  ? 'Choose a vehicle'
                                  : '${amount.toStringAsFixed(0)} RWF',
                              style: theme.textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Find a driver',
                      isLoading: state.status == CreateRequestStatus.submitting,
                      onPressed: state.canSubmit
                          ? () {
                              final uid = context
                                  .read<AuthBloc>()
                                  .state
                                  .user
                                  ?.uid;
                              if (uid == null) {
                                showAppSnackBar(
                                  context,
                                  'Please sign in again',
                                  type: SnackBarType.error,
                                );
                                return;
                              }
                              bloc.add(RequestSubmitted(uid));
                            }
                          : null,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Sends the user back to where_from_to when there is no route to show.
class _BackToStart extends StatelessWidget {
  const _BackToStart();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.go(AppRoutes.whereFromTo);
    });
    return const LoadingView();
  }
}
