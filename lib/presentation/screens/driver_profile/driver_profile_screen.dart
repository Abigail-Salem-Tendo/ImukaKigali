

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/vehicle.dart';
import '../../../domain/repositories/vehicle_repository.dart';
import '../driver_registration_step2/vehicle_type_card.dart';
import '../login/auth_bloc.dart';
import 'driver_profile_bloc.dart';
import 'plate_number_dialog.dart';
import 'profile_widgets.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Name, phone and email come from the global AuthBloc (Member 1),
    // which loaded them when the driver logged in.
    final user = context.select((AuthBloc bloc) => bloc.state.user);
    if (user == null) {
      return const _LoggedOutView();
    }

    return BlocProvider(
      create: (ctx) => DriverProfileBloc(ctx.read<VehicleRepository>())
        ..add(DriverProfileRequested(user.uid)),
      child: _DriverProfileView(user: user),
    );
  }
}

class _DriverProfileView extends StatelessWidget {
  const _DriverProfileView({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Error snackbars: whenever the status turns into "failure".
        BlocListener<DriverProfileBloc, DriverProfileState>(
          listenWhen: (previous, current) =>
          previous.status != current.status &&
              current.status == DriverProfileStatus.failure,
          listener: (context, state) => showAppSnackBar(
            context,
            state.error ?? 'Something went wrong. Please try again.',
          ),
        ),
        // Success snackbars, e.g. "Vehicle removed."
        BlocListener<DriverProfileBloc, DriverProfileState>(
          listenWhen: (previous, current) =>
          current.message != null && previous.message != current.message,
          listener: (context, state) =>
              showAppSnackBar(context, state.message ?? 'Saved.'),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(title: const _ProfileTitle()),
        body: SafeArea(
          child: BlocBuilder<DriverProfileBloc, DriverProfileState>(
            builder: (context, state) {
              if (!state.hasLoaded) {
                if (state.status == DriverProfileStatus.failure) {
                  return _LoadError(
                    onRetry: () => context
                        .read<DriverProfileBloc>()
                        .add(DriverProfileRequested(user.uid)),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              }
              return _ProfileContent(user: user, state: state);
            },
          ),
        ),
      ),
    );
  }
}

/// What the Edit button's menu can do.
enum _EditChoice { vehicleClass, plate }

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.user, required this.state});

  final AppUser user;
  final DriverProfileState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DriverProfileBloc>();
    final vehicle = state.vehicle;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        ProfileHeaderCard(
          fullName: user.fullName,
          phone: user.phone,
          email: user.email,
          onEditPressed:
          vehicle == null ? null : () => _showEditMenu(context, vehicle),
        ),
        const SizedBox(height: AppSpacing.lg),
        const PerformanceSnapshot(),
        const SizedBox(height: AppSpacing.lg),
        if (vehicle == null)
          NoVehicleCard(
            isSaving: state.isSaving,
            onAddPressed: () => _addVehicle(context),
          )
        else ...[
          RegisteredVehicleCard(
            vehicle: vehicle,
            onChangeClassPressed: () => _changeVehicleType(context, vehicle),
            onEditPlatePressed: () => _editPlate(context, vehicle),
            onRemovePressed: () => _removeVehicle(context),
          ),
          const SizedBox(height: AppSpacing.md),
          OperatingZonesCard(
            selectedHubs: vehicle.operatingHubs,
            district: vehicle.baseDistrict,
            onHubToggled: (hub) => bloc.add(DriverHubToggled(hub)),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AccountSection(
          onSettingsPressed: () => context.push(AppRoutes.settings),
        ),
        const SizedBox(height: AppSpacing.lg),
        LogoutButton(
          // AuthBloc (Member 1) signs out and clears the session. The router
          // then sends the driver back to the login screen.
          onPressed: () => context.read<AuthBloc>().add(const LogoutRequested()),
        ),
      ],
    );
  }

  // Each method below first grabs the bloc, THEN waits for the driver to
  // answer a dialog. Grabbing it first means we never use "context" after
  // waiting, which Flutter warns about (the screen might be gone by then).

  /// The header's Edit button: a small menu of what can be changed.
  Future<void> _showEditMenu(BuildContext context, Vehicle vehicle) async {
    final choice = await showModalBottomSheet<_EditChoice>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Change vehicle class'),
              onTap: () =>
                  Navigator.pop(sheetContext, _EditChoice.vehicleClass),
            ),
            ListTile(
              leading: const Icon(Icons.confirmation_number_outlined),
              title: const Text('Edit plate number'),
              onTap: () => Navigator.pop(sheetContext, _EditChoice.plate),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) {
      return;
    }
    switch (choice) {
      case _EditChoice.vehicleClass:
        await _changeVehicleType(context, vehicle);
      case _EditChoice.plate:
        await _editPlate(context, vehicle);
      case null:
        break; // The driver closed the menu without choosing.
    }
  }

  Future<void> _changeVehicleType(BuildContext context, Vehicle vehicle) async {
    final bloc = context.read<DriverProfileBloc>();
    final type = await _pickVehicleType(context, current: vehicle.vehicleType);
    if (type != null) {
      bloc.add(DriverVehicleTypeChanged(type));
    }
  }

  Future<void> _editPlate(BuildContext context, Vehicle vehicle) async {
    final bloc = context.read<DriverProfileBloc>();
    final plate = await showPlateNumberDialog(
      context,
      initialPlate: vehicle.plateNumber,
    );
    if (plate != null) {
      bloc.add(DriverPlateNumberChanged(plate));
    }
  }

  Future<void> _addVehicle(BuildContext context) async {
    final bloc = context.read<DriverProfileBloc>();
    final type = await _pickVehicleType(context);
    if (type == null) {
      return; // The driver closed the sheet.
    }
    if (!context.mounted) {
      return; // The screen closed while the sheet was open.
    }
    final plate = await showPlateNumberDialog(context);
    if (plate != null) {
      bloc.add(DriverVehicleAdded(vehicleType: type, plateNumber: plate));
    }
  }

  Future<void> _removeVehicle(BuildContext context) async {
    final bloc = context.read<DriverProfileBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          icon: const Icon(Icons.delete_outline),
          title: const Text('Remove this vehicle?'),
          content: const Text(
            "You won't receive move requests until you add a vehicle again.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
    // "confirmed" is null if the driver tapped outside the dialog.
    if (confirmed ?? false) {
      bloc.add(const DriverVehicleDeleted());
    }
  }
}

/// A bottom sheet listing the three vehicle classes (same cards as Step 2).
/// Returns the class the driver tapped, or null if they closed the sheet.
Future<VehicleType?> _pickVehicleType(
    BuildContext context, {
      VehicleType? current,
    }) {
  return showModalBottomSheet<VehicleType>(
    context: context,
    // Lets the sheet grow taller and scroll, so it fits in landscape too.
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose your vehicle class',
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final type in VehicleType.values)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: VehicleTypeCard(
                  vehicleType: type,
                  selected: type == current,
                  onTap: () => Navigator.pop(sheetContext, type),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// The app bar title: "IMUKA KIGALI" above "Profile".
class _ProfileTitle extends StatelessWidget {
  const _ProfileTitle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'IMUKA KIGALI',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            letterSpacing: 1,
          ),
        ),
        const Text('Profile'),
      ],
    );
  }
}

/// Shown if the vehicle could not be loaded the first time.
class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: AppSpacing.xl,
              color: colors.error,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              "We couldn't load your profile.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

/// Shown for a moment after logout, before the router opens the login screen.
class _LoggedOutView extends StatelessWidget {
  const _LoggedOutView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your session has ended. Please log in again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Go to login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
