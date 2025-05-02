// lib/widgets/custom_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 100,
      child: Stack(
        children: [
          //  ───────────────────────────────────
          //  the "tray" behind your buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: cs.surface, // ← theme surface for contrast
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
          ),

          //  ───────────────────────────────────
          //  centre "Calma" pill — untouched layout, but theme‑driven colors
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => context.go('/breath'),
              child: Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        cs.primary,
                        cs.primary.withOpacity(0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
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

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: isSelected
                ? cs.primary
                : cs.onSurface.withOpacity(0.6), // ← theme muted grey
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
