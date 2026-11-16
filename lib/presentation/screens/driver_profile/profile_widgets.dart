import 'package:flutter/material.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';
import 'package:imuka_kigali/domain/entities/vehicle.dart';
import 'package:imuka_kigali/domain/entities/vehicle_class.dart';
import 'package:imuka_kigali/presentation/screens/driver_registration_step2/vehicle_type_card.dart';

/// Writes a saved phone number with spaces: "+250788452910" becomes
/// "+250 788 452 910". Any other text is returned unchanged.
String _formatPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 12 || !digits.startsWith('250')) {
    return phone;
  }
  return '+250 ${digits.substring(3, 6)} ${digits.substring(6, 9)} '
      '${digits.substring(9)}';
}

/// The card at the top of the profile: a coloured banner with the
/// driver's initials, then their name, phone and email.
class ProfileHeaderCard extends StatelessWidget {
  /// Creates the card. When [onEditPressed] is null the Edit button is
  /// hidden.
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
  final VoidCallback? onEditPressed;

  /// Returns the first letters of the first two names:
  /// "Jean-Claude Mugisha" becomes "JM".
  String get _initials {
    final words = fullName.trim().split(RegExp(r'\s+'));
    return words
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();
  }

  /// Draws the banner, the name row with the Edit button, and the
  /// contact box.
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
            padding: AppSpacing.cardInsets,
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
            padding: AppSpacing.cardInsets,
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
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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

/// One line of contact details: an icon followed by text.
class _ContactRow extends StatelessWidget {
  /// Creates the row with its icon and text.
  const _ContactRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  /// Draws the icon and the text. Long text is cut with "…".
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: AppSpacing.iconSm, color: theme.colorScheme.primary),
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

/// Three tiles showing the driver's rating, completed trips and earnings.
/// A value that is not passed in is shown as "—".
class PerformanceSnapshot extends StatelessWidget {
  /// Creates the snapshot. Every value is optional.
  const PerformanceSnapshot({
    super.key,
    this.rating,
    this.completedTrips,
    this.earningsRwf,
  });

  final double? rating;
  final int? completedTrips;
  final int? earningsRwf;

  /// Draws the heading and the three tiles in one row.
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

/// One tile of the performance snapshot.
class _StatTile extends StatelessWidget {
  /// Creates the tile with its icon, label, big value and small caption.
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

  /// Draws the label row, the value and the caption inside a card.
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
                Icon(icon, size: AppSpacing.iconSm, color: colors.primary),
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

/// The "Registered Vehicle" card: the vehicle's photo with its plate on
/// top, its capacity and rate, and the buttons that change it.
class RegisteredVehicleCard extends StatelessWidget {
  /// Creates the card. Each callback runs when its button is tapped.
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

  /// Draws the title, the photo with the plate badge, the details box
  /// and the three action buttons.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final vehicleClass = VehicleClasses.of(vehicle.vehicleType);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.cardInsets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                VehicleTypeIcon(vehicleClass: vehicleClass),
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
                        '${vehicleClass.shortLabel} Class',
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
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    VehicleTypePhoto(vehicleClass: vehicleClass),
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
              width: double.infinity,
              padding: AppSpacing.cardInsets,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicleClass.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Capacity: ${vehicle.capacityKg.round()} kg',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'Rate: ${vehicleClass.rateLabel}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Wrap moves a button to the next line on a narrow phone.
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

/// The dark badge that shows a licence plate, for example "RAD 428 E".
class PlateBadge extends StatelessWidget {
  /// Creates the badge for one plate number.
  const PlateBadge({super.key, required this.plate});

  final String plate;

  /// Draws the plate in bold, light text on a dark rounded background.
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

/// The card shown in place of the vehicle card when the driver has no
/// vehicle.
class NoVehicleCard extends StatelessWidget {
  /// Creates the card. While [isSaving] is true the button shows a
  /// spinner and cannot be tapped.
  const NoVehicleCard({
    super.key,
    required this.isSaving,
    required this.onAddPressed,
  });

  final bool isSaving;
  final VoidCallback onAddPressed;

  /// Draws an icon, a short explanation and the "Add vehicle" button.
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
              size: AppSpacing.iconLg,
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
                      dimension: AppSpacing.iconSm,
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

/// The "Operational Zone" card: the district the driver works from.
class OperatingZoneCard extends StatelessWidget {
  /// Creates the card for one district name.
  const OperatingZoneCard({super.key, required this.district});

  final String district;

  /// Draws the title and the district as a chip. An empty district is
  /// shown as "Not set".
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.cardInsets,
        child: Row(
          children: [
            Icon(Icons.explore_outlined, color: colors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Operational Zone',
                style: theme.textTheme.titleMedium,
              ),
            ),
            Chip(
              label: Text(district.isEmpty ? 'Not set' : '$district District'),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

/// The "ACCOUNT & COMPLIANCE" list: the link to Settings and the driver
/// support hotline.
class AccountSection extends StatelessWidget {
  /// Creates the section. [onSettingsPressed] runs when "App Settings"
  /// is tapped.
  const AccountSection({super.key, required this.onSettingsPressed});

  final VoidCallback onSettingsPressed;

  /// Draws the heading and the two list rows inside a card.
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

/// The "Log Out Partner Account" button at the bottom of the profile.
class LogoutButton extends StatelessWidget {
  /// Creates the button. [onPressed] runs when it is tapped.
  const LogoutButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  /// Draws a full-width button in the theme's soft error colours.
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: colors.errorContainer,
        foregroundColor: colors.onErrorContainer,
        minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.logout),
      label: const Text('Log Out Partner Account'),
    );
  }
}
