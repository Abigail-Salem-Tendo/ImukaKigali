import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/core/widgets/app_snack_bar.dart';
import 'package:imuka_kigali/domain/entities/app_user.dart';
import 'package:imuka_kigali/domain/entities/vehicle.dart';
import 'package:imuka_kigali/domain/entities/vehicle_class.dart';
import 'package:imuka_kigali/domain/repositories/vehicle_repository.dart';
import 'package:imuka_kigali/presentation/screens/driver_profile/driver_profile_bloc.dart';
import 'package:imuka_kigali/presentation/screens/driver_profile/plate_number_dialog.dart';
import 'package:imuka_kigali/presentation/screens/driver_profile/profile_widgets.dart';
import 'package:imuka_kigali/presentation/screens/driver_registration_step2/vehicle_type_card.dart';
import 'package:imuka_kigali/presentation/screens/login/auth_bloc.dart';

/// The driver profile: the driver's details and their vehicle, which they
/// can change, remove and add again.
class DriverProfileScreen extends StatelessWidget {
  /// Creates the screen. It needs no data.
  const DriverProfileScreen({super.key});

  /// Reads the signed-in user from the global AuthBloc. With a user, it
  /// creates the DriverProfileBloc and asks it to load the vehicle.
  /// Without one, it shows a small "session ended" view.
  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => bloc.state.user);
    if (user == null) {
      return const _LoggedOutView();
    }

    return BlocProvider(
      create: (ctx) =>
          DriverProfileBloc(ctx.read<VehicleRepository>())
            ..add(DriverProfileRequested(user.uid)),
      child: _DriverProfileView(user: user),
    );
  }
}

/// The profile page with its snackbar listeners.
class _DriverProfileView extends StatelessWidget {
  /// Creates the view for the signed-in [user].
  const _DriverProfileView({required this.user});

  final AppUser user;

  /// Draws the page. One listener shows error snackbars, another shows
  /// success snackbars. The body shows a spinner while loading, a retry
  /// view if the first load failed, and the profile content otherwise.
  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DriverProfileBloc, DriverProfileState>(
          listenWhen: (previous, current) =>
              previous.status != current.status &&
              current.status == DriverProfileStatus.failure,
          listener: (context, state) => showAppSnackBar(
            context,
            state.error ?? 'Something went wrong. Please try again.',
          ),
        ),
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
                    onRetry: () => context.read<DriverProfileBloc>().add(
                      DriverProfileRequested(user.uid),
                    ),
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

/// The choices in the Edit button's menu.
enum _EditChoice { vehicleClass, plate }

/// The scrolling list of profile cards.
class _ProfileContent extends StatelessWidget {
  /// Creates the content for the [user] and the bloc's current [state].
  const _ProfileContent({required this.user, required this.state});

  final AppUser user;
  final DriverProfileState state;

  /// Draws the header, the performance tiles, the vehicle card (or the
  /// "no vehicle" card), the zone, the account links and the logout
  /// button. A ListView is used so nothing overflows in landscape.
  @override
  Widget build(BuildContext context) {
    final vehicle = state.vehicle;

    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        ProfileHeaderCard(
          fullName: user.fullName,
          phone: user.phone,
          email: user.email,
          onEditPressed: vehicle == null
              ? null
              : () => _showEditMenu(context, vehicle),
        ),
        const SizedBox(height: AppSpacing.lg),
        const PerformanceSnapshot(),
        const SizedBox(height: AppSpacing.lg),
        if (vehicle == null)
          NoVehicleCard(
            isSaving: state.isSaving,
            onAddPressed: () => _addVehicle(context),
          )
        else
          RegisteredVehicleCard(
            vehicle: vehicle,
            onChangeClassPressed: () => _changeVehicleType(context, vehicle),
            onEditPlatePressed: () => _editPlate(context, vehicle),
            onRemovePressed: () => _removeVehicle(context),
          ),
        const SizedBox(height: AppSpacing.md),
        OperatingZoneCard(district: user.district),
        const SizedBox(height: AppSpacing.lg),
        AccountSection(
          onSettingsPressed: () => context.push(AppRoutes.settings),
        ),
        const SizedBox(height: AppSpacing.lg),
        LogoutButton(
          onPressed: () =>
              context.read<AuthBloc>().add(const LogoutRequested()),
        ),
      ],
    );
  }

  /// Opens a bottom menu with "Change vehicle class" and "Edit plate
  /// number", then starts the action the driver chose.
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
    // The screen may have closed while the menu was open.
    if (!context.mounted) {
      return;
    }
    switch (choice) {
      case _EditChoice.vehicleClass:
        await _changeVehicleType(context, vehicle);
      case _EditChoice.plate:
        await _editPlate(context, vehicle);
      case null:
        break;
    }
  }

  /// Lets the driver pick a new vehicle type and sends it to the bloc.
  /// The bloc is read before waiting, so the context is not used after
  /// the sheet closes.
  Future<void> _changeVehicleType(BuildContext context, Vehicle vehicle) async {
    final bloc = context.read<DriverProfileBloc>();
    final type = await _pickVehicleType(context, current: vehicle.vehicleType);
    if (type != null) {
      bloc.add(DriverVehicleTypeChanged(type));
    }
  }

  /// Opens the plate dialog filled with the current plate and sends the
  /// new plate to the bloc.
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

  /// Asks for a vehicle type, then a plate number, and sends both to the
  /// bloc to create the vehicle. Closing either step cancels the add.
  Future<void> _addVehicle(BuildContext context) async {
    final bloc = context.read<DriverProfileBloc>();
    final type = await _pickVehicleType(context);
    if (type == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    final plate = await showPlateNumberDialog(context);
    if (plate != null) {
      bloc.add(DriverVehicleAdded(vehicleType: type, plateNumber: plate));
    }
  }

  /// Asks "Remove this vehicle?" and, if the driver confirms, tells the
  /// bloc to delete it.
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
    // confirmed is null when the driver taps outside the dialog.
    if (confirmed ?? false) {
      bloc.add(const DriverVehicleDeleted());
    }
  }
}

/// Opens a bottom sheet listing every vehicle type as a card.
/// Returns the type string the driver tapped, or null if they closed the
/// sheet. [current] marks the type that is selected now.
Future<String?> _pickVehicleType(BuildContext context, {String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    // Lets the sheet grow and scroll, so it also fits in landscape.
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
            for (final vehicleClass in VehicleClasses.all)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: VehicleTypeCard(
                  vehicleClass: vehicleClass,
                  selected: vehicleClass.type == current,
                  onTap: () => Navigator.pop(sheetContext, vehicleClass.type),
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
  /// Creates the title. It needs no data.
  const _ProfileTitle();

  /// Draws the two lines of the title.
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

/// The view shown when the vehicle could not be loaded the first time.
class _LoadError extends StatelessWidget {
  /// Creates the view. [onRetry] runs when "Try again" is tapped.
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  /// Draws an icon, a short message and the "Try again" button.
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
              size: AppSpacing.iconLg,
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

/// The view shown when nobody is signed in, for example just after logout.
class _LoggedOutView extends StatelessWidget {
  /// Creates the view. It needs no data.
  const _LoggedOutView();

  /// Draws a message and a button that opens the login screen.
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
