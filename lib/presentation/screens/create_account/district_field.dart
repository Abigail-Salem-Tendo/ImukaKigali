// Owner: Member 1
// The three Kigali district cards, used by Create Account and by
// Complete Your Profile.
import 'package:flutter/material.dart';

import '../../../core/constants/kigali_districts.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';

/// A few well-known areas in each district, shown on the cards so the user
/// can recognise where they live. Only for display: what gets saved is the
/// district name itself.
const _knownAreas = {
  KigaliDistricts.gasabo: 'Kimihurura / Kacyiru',
  KigaliDistricts.kicukiro: 'Niboye / Gahanga',
  KigaliDistricts.nyarugenge: 'Kiyovu / Nyamirambo',
};

/// A FormField keeps the chosen district and its error message itself, so
/// it is checked by Form.validate() together with the text fields, and the
/// screen doesn't have to redraw anything.
class DistrictField extends StatelessWidget {
  const DistrictField({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FormField<String>(
      validator: (value) => value == null ? 'Choose your district' : null,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your District', style: textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (final district in KigaliDistricts.all) ...[
                if (district != KigaliDistricts.all.first)
                  const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppCard(
                    highlighted: field.value == district,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    onTap: () {
                      field.didChange(district);
                      onChanged(district);
                    },
                    child: Column(
                      children: [
                        Text(district, style: textTheme.labelLarge),
                        Text(
                          _knownAreas[district]!,
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (field.hasError)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                field.errorText!,
                style: textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
