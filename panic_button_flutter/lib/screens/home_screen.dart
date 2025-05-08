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
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(bottom: 70), // Add padding for navbar
              child: Center(
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
                        'Cuando sientas un ataque de pánico, presiona el botón para iniciar un ejercicio de respiración guiada de 3 minutos.',
                        style: tt.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: Icon(Icons.settings, color: cs.onSurface),
                onPressed: () => context.push('/settings'),
              ),
            ),
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CustomNavBar(currentIndex: 1),
            ),
          ],
        ),
      ),
    );
  }
}
