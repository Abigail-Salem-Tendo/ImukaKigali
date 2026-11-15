import 'package:flutter/material.dart';
import 'package:imuka_kigali/core/constants/kigali_areas.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';

/// A tappable field that opens a searchable list of Kigali areas.
/// Only used by where_from_to.
class AreaPicker extends StatelessWidget {
  const AreaPicker({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
    this.excluded,
  });

  final String label;
  final IconData icon;
  final KigaliArea? selected;
  final KigaliArea? excluded;
  final ValueChanged<KigaliArea> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SearchAnchor(
      builder: (context, controller) => InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
        onTap: controller.openView,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            suffixIcon: const Icon(Icons.search),
          ),
          child: Text(
            selected?.name ?? 'Choose an area',
            style: selected == null
                ? TextStyle(color: scheme.onSurfaceVariant)
                : null,
          ),
        ),
      ),
      suggestionsBuilder: (context, controller) {
        final query = controller.text.trim().toLowerCase();
        final matches = KigaliAreas.all.where(
          (a) =>
              a.name != excluded?.name && a.name.toLowerCase().contains(query),
        );
        if (matches.isEmpty) {
          return [
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Text('No area found'),
            ),
          ];
        }
        return [
          for (final area in matches)
            ListTile(
              leading: const Icon(Icons.place_outlined),
              title: Text(area.name),
              onTap: () {
                onSelected(area);
                controller.closeView('');
              },
            ),
        ];
      },
    );
  }
}
