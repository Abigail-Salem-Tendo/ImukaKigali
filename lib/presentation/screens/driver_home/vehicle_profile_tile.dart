// Owner: Member 4
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:imuka_kigali/core/constants/app_routes.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/core/widgets/widgets.dart';
import 'package:imuka_kigali/domain/entities/vehicle.dart';
// Member 2's formatRwf(int) clashes with mine in job_log_format.dart, so it
// is hidden until the group agrees on one shared formatRwf.
import 'package:imuka_kigali/domain/entities/vehicle_class.dart' hide formatRwf;

class VehicleProfileTile extends StatelessWidget {
  const VehicleProfileTile({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final vehicleLabel = VehicleClasses.of(vehicle.vehicleType).shortLabel;

    return AppCard(
      onTap: () => context.push(AppRoutes.driverProfile),
      child: Row(
        children: [
          CircleAvatar(
            radius: AppSpacing.lg,
            backgroundColor: scheme.secondaryContainer,
            child: Icon(
              Icons.badge_outlined,
              color: scheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vehicle Fleet Profile',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$vehicleLabel • ${vehicle.plateNumber}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
