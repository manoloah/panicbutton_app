import 'package:flutter/material.dart';

/// A widget that displays an icon indicating the breathing method (nose, mouth, or both)
class BreathingMethodIndicator extends StatelessWidget {
  final String method;
  final double size;

  const BreathingMethodIndicator({
    Key? key,
    required this.method,
    this.size = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final IconData iconData = _getIconForMethod(method);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.2),
        child: Icon(
          iconData,
          color: Theme.of(context).colorScheme.primary,
          size: size * 0.6,
        ),
      ),
    );
  }

  IconData _getIconForMethod(String method) {
    switch (method.toLowerCase()) {
      case 'nose':
        return Icons.air_rounded; // Better icon for nose breathing
      case 'mouth':
        return Icons.water_drop; // Better icon for mouth breathing
      case 'nose+mouth':
      case 'both':
        return Icons.vertical_align_center; // Better icon for both
      default:
        return Icons.air_rounded;
    }
  }
}
