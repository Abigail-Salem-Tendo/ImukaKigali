
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/vehicle.dart';

class VehicleTypeCard extends StatelessWidget {
  const VehicleTypeCard({
    super.key,
    required this.vehicleType,
    required this.selected,
    required this.onTap,
  });

  final VehicleType vehicleType;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isTricycle = vehicleType == VehicleType.tricycle;

    // Semantics tells screen readers this card is a button and if it is picked.
    return Semantics(
      button: true,
      selected: selected,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VehicleTypePhoto(
                      vehicleType: vehicleType,
                      width: 88,
                      height: 62,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicleType.label,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _PlateSeriesTag(
                            text: vehicleType.plateSeries,
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
                  vehicleType.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // The per-minute price for this class of vehicle.
                Row(
                  children: [
                    Icon(Icons.timer_outlined,
                        size: AppSpacing.md, color: colors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      vehicleType.rateLabel,
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

/// The vehicle's photo from assets/vehicles/, with rounded corners.
/// Leave [width] and [height] empty to fill the space it is given.
/// If the photo is missing, it shows [VehicleTypeIcon] instead of crashing.
class VehicleTypePhoto extends StatelessWidget {
  const VehicleTypePhoto({
    super.key,
    required this.vehicleType,
    this.width,
    this.height,
  });

  final VehicleType vehicleType;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: Image.asset(
        vehicleType.photo,
        width: width,
        height: height,
        fit: BoxFit.cover,
        semanticLabel: vehicleType.shortLabel,
        errorBuilder: (context, error, stackTrace) =>
            VehicleTypeIcon(vehicleType: vehicleType),
      ),
    );
  }
}

/// A coloured square with the right icon inside (used when there is no photo).
class VehicleTypeIcon extends StatelessWidget {
  const VehicleTypeIcon({super.key, required this.vehicleType});

  final VehicleType vehicleType;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // A "switch expression" picks one icon for each vehicle class.
    final icon = switch (vehicleType) {
      VehicleType.tricycle => Icons.two_wheeler,
      VehicleType.pickup => Icons.airport_shuttle,
      VehicleType.boxTruck => Icons.local_shipping,
      VehicleType.largeTruck => Icons.local_shipping_outlined,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Icon(icon, color: colors.onPrimaryContainer),
    );
  }
}

/// The small coloured tag, e.g. "Motorbike / Tricycle Plate Series".
/// Tricycles get a different colour because their plates are different.
class _PlateSeriesTag extends StatelessWidget {
  const _PlateSeriesTag({required this.text, required this.highlight});

  final String text;
  final bool highlight;

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
