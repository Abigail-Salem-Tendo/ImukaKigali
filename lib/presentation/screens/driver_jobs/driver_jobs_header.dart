// Owner: Member 4
import 'package:flutter/material.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/core/widgets/widgets.dart';
import 'package:imuka_kigali/domain/entities/vehicle.dart';
// Member 2's formatRwf(int) clashes with mine in job_log_format.dart, so it
// is hidden until the group agrees on one shared formatRwf.
import 'package:imuka_kigali/domain/entities/vehicle_class.dart' hide formatRwf;

class DriverJobsHeader extends StatelessWidget {
  const DriverJobsHeader({
    super.key,
    required this.district,
    required this.vehicle,
  });

  final String district;
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicleClass = VehicleClasses.of(vehicle.vehicleType);

    return AppCard(
      highlighted: true,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.my_location,
              size: AppSpacing.iconMd,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  district.isEmpty ? 'Kigali' : '$district District Hub',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${vehicleClass.shortLabel} • '
                  'Max load ${vehicleClass.capacityLabel}',
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
