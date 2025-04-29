import 'package:flutter/material.dart';

class BreathingCircle extends StatelessWidget {
  final bool isBreathing;
  final VoidCallback onTap;
  final Widget child;

  const BreathingCircle({
    super.key,
    required this.isBreathing,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.primary, // brand green
          boxShadow: [
            BoxShadow(
              color: cs.primary.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
