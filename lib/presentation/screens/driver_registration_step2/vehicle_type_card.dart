import 'package:flutter/material.dart';
import 'package:imuka_kigali/core/constants/pricing.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/domain/entities/vehicle_class.dart';

/// A tappable card for one vehicle type, with its photo, capacity and
/// price per km. Registration step 2 and the driver profile use it.
class VehicleTypeCard extends StatelessWidget {
  /// Creates the card. [selected] draws it with a highlighted border and
  /// [onTap] runs when the driver taps it.
  const VehicleTypeCard({
    super.key,
    required this.vehicleClass,
    required this.selected,
    required this.onTap,
  });

  final VehicleClass vehicleClass;
  final bool selected;
  final VoidCallback onTap;

  /// Draws the photo, name, plate tag, description and price of the type.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isTricycle = vehicleClass.type == VehicleTypes.tricycle;

    // Semantics tells screen readers that the card is a button.
    return Semantics(
      button: true,
      selected: selected,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : AppSpacing.borderWidth,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: AppSpacing.cardInsets,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VehicleTypePhoto(
                      vehicleClass: vehicleClass,
                      width: 88,
                      height: 62,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicleClass.label,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _PlateSeriesTag(
                            text: vehicleClass.plateSeries,
                            highlight: isTricycle,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: selected ? colors.primary : colors.outline,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Up to ${vehicleClass.capacityLabel} • '
                  '${vehicleClass.description}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: AppSpacing.iconSm,
                      color: colors.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      vehicleClass.rateLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The photo of a vehicle type, with rounded corners.
class VehicleTypePhoto extends StatelessWidget {
  /// Creates the photo. Leave [width] and [height] empty to let it fill
  /// the space its parent gives it.
  const VehicleTypePhoto({
    super.key,
    required this.vehicleClass,
    this.width,
    this.height,
  });

  final VehicleClass vehicleClass;
  final double? width;
  final double? height;

  /// Draws the photo from the app's assets. If the photo cannot be
  /// loaded, it draws the type's icon so the screen still works.
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Image.asset(
        vehicleClass.photo,
        width: width,
        height: height,
        fit: BoxFit.cover,
        semanticLabel: vehicleClass.shortLabel,
        errorBuilder: (context, error, stackTrace) =>
            VehicleTypeIcon(vehicleClass: vehicleClass),
      ),
    );
  }
}

/// A coloured square with an icon for a vehicle type.
class VehicleTypeIcon extends StatelessWidget {
  /// Creates the icon for one vehicle type.
  const VehicleTypeIcon({super.key, required this.vehicleClass});

  final VehicleClass vehicleClass;

  /// Picks the icon that matches the vehicle type and draws it on a
  /// coloured background.
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final icon = switch (vehicleClass.type) {
      VehicleTypes.tricycle => Icons.two_wheeler,
      VehicleTypes.pickup => Icons.airport_shuttle,
      VehicleTypes.van => Icons.local_shipping,
      _ => Icons.local_shipping_outlined,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Icon(icon, color: colors.onPrimaryContainer),
    );
  }
}

/// The small coloured tag that names the plate series of a vehicle type.
class _PlateSeriesTag extends StatelessWidget {
  /// Creates the tag. [highlight] gives it a different colour, used for
  /// tricycles because their plates are different.
  const _PlateSeriesTag({required this.text, required this.highlight});

  final String text;
  final bool highlight;

  /// Draws the text on a rounded, coloured background.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: highlight ? colors.tertiaryContainer : colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: highlight
              ? colors.onTertiaryContainer
              : colors.onPrimaryContainer,
        ),
      ),
    );
  }
}
