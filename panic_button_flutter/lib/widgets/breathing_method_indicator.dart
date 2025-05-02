import 'package:flutter/material.dart';

class BreathingMethodIndicator extends StatelessWidget {
  final String phase;
  final String? method;
  final bool isActive;

  const BreathingMethodIndicator({
    super.key,
    required this.phase,
    this.method,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    if (method == null || (phase != 'Inhala' && phase != 'Exhala')) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isNose = method == 'nose';
    final iconData = isNose ? Icons.emoji_people : Icons.spatial_audio;

    return Positioned(
      bottom: 8,
      right: phase == 'Inhala' ? null : 8,
      left: phase == 'Inhala' ? 8 : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primary.withOpacity(0.8)
              : theme.colorScheme.secondary.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconData,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              isNose ? 'Nariz' : 'Boca',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
