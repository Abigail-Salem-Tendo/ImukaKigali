
// The cards that make up the driver profile (Figma frame: "Driver Profile").
// Each one only DRAWS. Taps are passed back to the screen through callbacks,
// and the screen sends the matching event to DriverProfileBloc.

import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/vehicle.dart';
import '../driver_registration_step2/vehicle_type_card.dart';

/// "+250788452910" -> "+250 788 452 910" (anything else is shown as it is).
String _formatPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 12 || !digits.startsWith('250')) {
    return phone;
  }
  return '+250 ${digits.substring(3, 6)} ${digits.substring(6, 9)} '
      '${digits.substring(9)}';
}

/// The top card: green banner, initials, "ACTIVE DRIVER", name and contacts.
class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.fullName,
    required this.phone,
    required this.email,
    this.onEditPressed,
  });

  final String fullName;
  final String phone;
  final String email;

  /// Null hides the Edit button (there is nothing to edit without a vehicle).
  final VoidCallback? onEditPressed;

  /// "Jean-Claude Mugisha" -> "JM"
  String get _initials {
    final words = fullName.trim().split(RegExp(r'\s+'));
    return words
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: colors.primary,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: AppSpacing.xl,
                  backgroundColor: colors.primaryContainer,
                  child: Text(
                    _initials,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
                const Spacer(),
                Chip(
                  avatar: Icon(
                    Icons.circle,
                    size: AppSpacing.sm,
                    color: colors.primary,
                  ),
                  label: const Text('ACTIVE DRIVER'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(fullName, style: theme.textTheme.titleLarge),
                    ),
                    if (onEditPressed != null)
                      OutlinedButton.icon(
                        onPressed: onEditPressed,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Imuka Kigali Driver Partner',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Column(
                    children: [
                      _ContactRow(
                        icon: Icons.phone_outlined,
                        text: _formatPhone(phone),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _ContactRow(icon: Icons.mail_outline, text: email),
                    ],
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

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: AppSpacing.md, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Rating, trips and earnings.
///
/// These numbers come from finished trips, ratings and payments, which
/// Members 4 and 5 build. Until that data is passed in, each tile shows "—".
class PerformanceSnapshot extends StatelessWidget {
  const PerformanceSnapshot({
    super.key,
    this.rating,
    this.completedTrips,
    this.earningsRwf,
  });

  final double? rating;
  final int? completedTrips;
  final int? earningsRwf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Performance Snapshot', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.star_rounded,
                label: 'RATING',
                value: rating?.toStringAsFixed(2) ?? '—',
                caption: 'average stars',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatTile(
                icon: Icons.local_shipping_outlined,
                label: 'TRIPS',
                value: completedTrips?.toString() ?? '—',
                caption: 'completed',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatTile(
                icon: Icons.payments_outlined,
                label: 'EARNINGS',
                value: earningsRwf?.toString() ?? '—',
                caption: 'RWF net',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: AppSpacing.md, color: colors.primary),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: theme.textTheme.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              caption,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// The "Registered Vehicle" card with its plate badge and edit buttons.
class RegisteredVehicleCard extends StatelessWidget {
  const RegisteredVehicleCard({
    super.key,
    required this.vehicle,
    required this.onChangeClassPressed,
    required this.onEditPlatePressed,
    required this.onRemovePressed,
  });

  final Vehicle vehicle;
  final VoidCallback onChangeClassPressed;
  final VoidCallback onEditPlatePressed;
  final VoidCallback onRemovePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                VehicleTypeIcon(vehicleType: vehicle.vehicleType),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Registered Vehicle',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        '${vehicle.vehicleType.shortLabel} Class',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // The vehicle photo with the plate on top, like the Figma.
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.md),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    VehicleTypePhoto(vehicleType: vehicle.vehicleType),
                    Positioned(
                      right: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                      child: PlateBadge(plate: vehicle.plateNumber),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(AppSpacing.md),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.vehicleType.label,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Capacity: ${vehicle.capacityKg} kg',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          'Rate: ${vehicle.vehicleType.rateLabel}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Wrap moves buttons to a new line if the phone is too narrow.
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                TextButton.icon(
                  onPressed: onChangeClassPressed,
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Change class'),
                ),
                TextButton.icon(
                  onPressed: onEditPlatePressed,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit plate'),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: colors.error),
                  onPressed: onRemovePressed,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The dark licence plate badge, e.g. "RAD 428 E".
class PlateBadge extends StatelessWidget {
  const PlateBadge({super.key, required this.plate});

  final String plate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.inverseSurface,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Text(
        plate,
        style: theme.textTheme.titleSmall?.copyWith(
          color: colors.onInverseSurface,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

/// Shown instead of the vehicle card when the driver has no vehicle.
class NoVehicleCard extends StatelessWidget {
  const NoVehicleCard({
    super.key,
    required this.isSaving,
    required this.onAddPressed,
  });

  final bool isSaving;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: AppSpacing.xl,
              color: colors.primary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('No vehicle registered', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Add your vehicle to start receiving move requests.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: isSaving ? null : onAddPressed,
              icon: isSaving
                  ? const SizedBox.square(
                dimension: AppSpacing.md,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.add),
              label: const Text('Add vehicle'),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Operational Zones": every hub as a chip; the picked ones are filled in.
class OperatingZonesCard extends StatelessWidget {
  const OperatingZonesCard({
    super.key,
    required this.selectedHubs,
    required this.district,
    required this.onHubToggled,
  });

  final List<String> selectedHubs;

  /// e.g. "Gasabo". Null when no hubs are picked yet.
  final String? district;

  final ValueChanged<String> onHubToggled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final districtName = district;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.explore_outlined, color: colors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Operational Zones',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (districtName != null)
                  Text(
                    '$districtName District',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tap a hub to add or remove it. Keep at least 2.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final hub in kigaliHubDistricts.keys)
                  FilterChip(
                    label: Text(hub),
                    selected: selectedHubs.contains(hub),
                    onSelected: (_) => onHubToggled(hub),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "ACCOUNT & COMPLIANCE": the link to Settings and the support hotline.
class AccountSection extends StatelessWidget {
  const AccountSection({super.key, required this.onSettingsPressed});

  final VoidCallback onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACCOUNT & COMPLIANCE',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('App Settings'),
                subtitle: const Text('Theme, notifications & default district'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onSettingsPressed,
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.support_agent),
                title: Text('Priority Driver Partner Hotline'),
                subtitle: Text('+250 788 000 111 (24/7 Dispatch)'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The soft red "Log Out Partner Account" button at the bottom.
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: colors.errorContainer,
        foregroundColor: colors.onErrorContainer,
        minimumSize: const Size.fromHeight(kMinInteractiveDimension),
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.logout),
      label: const Text('Log Out Partner Account'),
    );
  }
}
