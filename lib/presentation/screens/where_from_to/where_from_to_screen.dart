// Owner: Member 3
// Screen: Where from / where to (pickup, destination, time) (StatelessWidget, template: ARCHITECTURE.md Part 5)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/presentation/screens/where_from_to/area_picker.dart';
import 'package:imuka_kigali/presentation/screens/where_from_to/create_request_bloc.dart';

/// The CreateRequestBloc is provided by a ShellRoute in app_router.dart.
class WhereFromToScreen extends StatelessWidget {
  const WhereFromToScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // This screen sits in a ShellRoute, which has its own navigator, so
        // the AppBar can't see the client home behind it and shows no back
        // arrow by itself.
        leading: BackButton(onPressed: () => context.go(AppRoutes.clientHome)),
        title: const Text('Where to?'),
      ),
      body: SafeArea(
        child: BlocBuilder<CreateRequestBloc, CreateRequestState>(
          builder: (context, state) {
            final bloc = context.read<CreateRequestBloc>();
            final sameArea =
                state.pickup != null &&
                state.dropoff != null &&
                !state.hasRoute;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AreaPicker(
                    label: 'Pickup',
                    icon: Icons.trip_origin,
                    selected: state.pickup,
                    onSelected: (a) => bloc.add(PickupSelected(a)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AreaPicker(
                    label: 'Drop-off',
                    icon: Icons.location_on_outlined,
                    selected: state.dropoff,
                    excluded: state.pickup,
                    onSelected: (a) => bloc.add(DropoffSelected(a)),
                  ),
                  if (sameArea)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        'Pickup and drop-off must be different areas',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: AppSpacing.buttonHeight,
                    child: FilledButton(
                      onPressed: state.hasRoute
                          ? () => context.push(AppRoutes.itemDetails)
                          : null,
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
