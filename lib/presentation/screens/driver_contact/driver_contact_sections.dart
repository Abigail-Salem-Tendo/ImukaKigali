// Owner: Member 5
// The cards of the driver contact screen. Each one only draws what it is given.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/core/widgets/widgets.dart';
import 'package:imuka_kigali/domain/entities/app_user.dart';
import 'package:imuka_kigali/domain/entities/move_request.dart';
import 'package:imuka_kigali/domain/entities/vehicle.dart';
import 'package:imuka_kigali/domain/entities/vehicle_class.dart';
import 'package:imuka_kigali/presentation/screens/job_logs/job_log_format.dart';

/// The driver's name and phone, with a button to copy the number.
class DriverCard extends StatelessWidget {
  const DriverCard({super.key, required this.driver});

  final AppUser driver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = driver.fullName.isEmpty ? 'Your driver' : driver.fullName;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: AppSpacing.lg,
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  name[0].toUpperCase(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (driver.district.isNotEmpty)
                      Text(
                        driver.district,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          Row(
            children: [
              Icon(
                Icons.phone_outlined,
                size: AppSpacing.iconSm,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SelectableText(
                  driver.phone.isEmpty ? 'No phone number' : driver.phone,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (driver.phone.isNotEmpty)
                IconButton(
                  tooltip: 'Copy phone number',
                  icon: const Icon(Icons.copy_outlined),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: driver.phone));
                    if (context.mounted) {
                      showAppSnackBar(
                        context,
                        'Phone number copied',
                        type: SnackBarType.success,
                      );
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The driver's vehicle. If they have not saved one, shows the type the
/// client asked for.
class VehicleCard extends StatelessWidget {
  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.requestedType,
  });

  final Vehicle? vehicle;
  final String requestedType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicleClass = VehicleClasses.of(
      vehicle?.vehicleType ?? requestedType,
    );
    final plate = vehicle == null || vehicle!.plateNumber.isEmpty
        ? 'Plate not available'
        : formatRwandaPlate(vehicle!.plateNumber);

    return AppCard(
      child: Row(
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: AppSpacing.iconLg,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicleClass.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(plate, style: theme.textTheme.bodyLarge),
                Text(
                  vehicleClass.capacityLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The trip and the fixed price.
class PriceCard extends StatelessWidget {
  const PriceCard({super.key, required this.request});

  final MoveRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      highlighted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${request.pickupLocation} → ${request.dropoffLocation}',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text('Fixed price', style: theme.textTheme.bodyMedium),
              const SizedBox(width: AppSpacing.md),
              // Shrinks a long price instead of overflowing a small screen.
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    formatRwf(request.proposedAmount),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'The price is fixed, so there is nothing to negotiate.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown while the driver's details load, or when they could not be loaded.
class DriverDetailsNotice extends StatelessWidget {
  const DriverDetailsNotice({
    super.key,
    required this.loading,
    this.message,
    this.onRetry,
  });

  final bool loading;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: loading
          ? Row(
              children: [
                const SizedBox.square(
                  dimension: AppSpacing.iconSm,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Loading your driver',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message ?? 'We could not load your driver right now.',
                  style: theme.textTheme.bodyMedium,
                ),
                AppButton.text(
                  label: 'Try again',
                  expand: false,
                  onPressed: onRetry,
                ),
              ],
            ),
    );
  }
}
