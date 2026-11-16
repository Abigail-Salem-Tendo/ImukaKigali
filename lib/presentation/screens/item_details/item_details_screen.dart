import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';
import 'package:imuka_kigali/core/constants/pricing.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/presentation/screens/login/auth_bloc.dart';
import 'package:imuka_kigali/presentation/screens/where_from_to/create_request_bloc.dart';

/// Uses the CreateRequestBloc provided by the ShellRoute in app_router.dart.
class ItemDetailsScreen extends StatelessWidget {
  const ItemDetailsScreen({super.key});

  static String _label(String type) =>
      type[0].toUpperCase() + type.substring(1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<CreateRequestBloc, CreateRequestState>(
      listener: (context, state) {
        if (state.status == CreateRequestStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error ?? 'Something went wrong')),
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
              final bloc = context.read<CreateRequestBloc>();
              final amount = state.proposedAmount;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${state.pickup?.name} to ${state.dropoff?.name}',
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
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        for (final type in VehicleTypes.all)
                          ChoiceChip(
                            label: Text(_label(type)),
                            selected: state.vehicleType == type,
                            onSelected: (_) =>
                                bloc.add(VehicleTypeSelected(type)),
                          ),
                      ],
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
                    SizedBox(
                      height: AppSpacing.buttonHeight,
                      child: FilledButton(
                        onPressed: state.canSubmit
                            ? () {
                                final uid = context
                                    .read<AuthBloc>()
                                    .state
                                    .user
                                    ?.uid;
                                if (uid != null) {
                                  bloc.add(RequestSubmitted(uid));
                                }
                              }
                            : null,
                        child: state.status == CreateRequestStatus.submitting
                            ? const SizedBox.square(
                                dimension: AppSpacing.lg,
                                child: CircularProgressIndicator(),
                              )
                            : const Text('Find a driver'),
                      ),
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
