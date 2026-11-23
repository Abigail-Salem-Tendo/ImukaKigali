import 'package:flutter/material.dart';

/// A soft pulsing ring around a truck icon. Owns its AnimationController, which is the reason I made this is a StatefulWidget.
class PulseAnimation extends StatefulWidget {
  const PulseAnimation({super.key});

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  static const double _size = 160;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: _size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              return Transform.scale(
                scale: 0.5 + t * 0.5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withValues(alpha: 0.35 * (1 - t)),
                  ),
                  child: const SizedBox.expand(),
                ),
              );
            },
          ),
          CircleAvatar(
            radius: _size / 4,
            backgroundColor: scheme.primary,
            child: Icon(
              Icons.local_shipping,
              size: _size / 4,
              color: scheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
