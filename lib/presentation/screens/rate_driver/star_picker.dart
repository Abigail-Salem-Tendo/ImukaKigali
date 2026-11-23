// Owner: Member 5
import 'package:flutter/material.dart';
import 'package:imuka_kigali/core/theme/app_spacing.dart';

/// Five tappable stars and a word for the chosen number. It only draws the
/// [stars] it is given and calls [onSelected], so it holds no state.
class StarPicker extends StatelessWidget {
  const StarPicker({super.key, required this.stars, required this.onSelected});

  /// 0 means no star is chosen yet.
  final int stars;
  final ValueChanged<int> onSelected;

  static const List<String> _words = [
    'Tap a star to rate',
    'Poor',
    'Fair',
    'Good',
    'Very good',
    'Excellent',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var value = 1; value <= 5; value++)
              IconButton(
                tooltip: '$value ${value == 1 ? 'star' : 'stars'}',
                iconSize: AppSpacing.iconLg,
                // 48 logical pixels is the minimum comfortable tap size.
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () => onSelected(value),
                icon: Icon(
                  value <= stars ? Icons.star : Icons.star_border,
                  color: value <= stars
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _words[stars.clamp(0, 5)],
          style: theme.textTheme.titleMedium?.copyWith(
            color: stars == 0
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
