// lib/widgets/custom_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main navbar
          Container(
            height: 80,
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Base navbar container
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: cs.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _NavBarItem(
                        icon: Icons.map_outlined,
                        label: 'Tu camino',
                        isSelected: currentIndex == 0,
                        onTap: () => context.go('/journey'),
                      ),

                      // spacer for the centre button
                      const SizedBox(width: 80),

                      _NavBarItem(
                        icon: Icons.analytics_outlined,
                        label: 'Mídete',
                        isSelected: currentIndex == 2,
                        onTap: () => context.go('/bolt'),
                      ),
                    ],
                  ),
                ),

                // Centre "Calma" button with wider tap area
                Positioned(
                  top: -44,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        splashColor: cs.primary.withOpacity(0.3),
                        onTap: () {
                          // Navigate without autoStart flag
                          context.go('/breath');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0), // Expand tap area
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  cs.primary.withOpacity(0.9),
                                  cs.primary,
                                ],
                              ),
                              boxShadow: [
                                // Outer glow
                                BoxShadow(
                                  color: cs.primary.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                  offset: const Offset(0, 4),
                                ),
                                // Deeper shadow for 3D effect
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 8),
                                ),
                                // Top highlight for 3D effect
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                              border: Border.all(
                                color: cs.primaryContainer,
                                width: 3,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.self_improvement,
                                    color: cs.onPrimary, size: 32),
                                const SizedBox(height: 4),
                                Text(
                                  'Calma',
                                  style: TextStyle(
                                    color: cs.onPrimary,
                                    fontSize: 12,
                                    fontWeight: currentIndex == 1
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
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

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.6),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
