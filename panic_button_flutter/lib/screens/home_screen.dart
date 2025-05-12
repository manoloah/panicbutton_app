// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:panic_button_flutter/widgets/panic_button.dart';
import 'package:panic_button_flutter/widgets/custom_nav_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      // backgroundColor omitted → uses scaffoldBackgroundColor (#132737)
      extendBody: true, // Important for bottom nav bar to overlay content
      body: Stack(
        children: [
          // Safe area for the main content
          SafeArea(
            bottom: false, // Don't add padding at the bottom
            child: Stack(
              children: [
                // Main content
                Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.only(bottom: 80), // Space for navbar
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Encuentra la calma',
                            style: tt.displayMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 36), // Reduced from 48
                        const PanicButton(),
                        const SizedBox(height: 24), // Reduced from 32
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Está comprobado científicamente que practicar ejercicios de respiración reduce significativamente tu ansiedad y aumenta tu capacidad para manejar el estrés, reduciendo la probabilidad de ataques de pánico, asma o ansiedad.',
                            style: tt.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Settings button
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    icon: Icon(Icons.settings, color: cs.onSurface),
                    onPressed: () => context.push('/settings'),
                  ),
                ),
              ],
            ),
          ),

          // Navigation bar fixed to bottom with correct positioning
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomNavBar(currentIndex: 1),
          ),
        ],
      ),
    );
  }
}
