// Owner: Member 1
// Shared widget: BrandHeader. The app icon and "Imuka Kigali" shown at the
// top of the login and sign-up screens, with an optional line below it.
//
//   const BrandHeader()
//   const BrandHeader(subtitle: 'Residential Mover')
import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        // There is no logo image in the project yet, so a truck icon on a
        // dark rounded square stands in for it.
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.inverseSurface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Icon(
              Icons.local_shipping_outlined,
              color: scheme.onInverseSurface,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Imuka Kigali', style: textTheme.titleLarge),
            if (subtitle != null)
              Text(
                subtitle!,
                style: textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
