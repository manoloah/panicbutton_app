import 'package:flutter/material.dart';
import 'package:panic_button_flutter/widgets/custom_nav_bar.dart';

class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

  final journeySteps = const [
    {
      'id': 1,
      'title': 'Respiración Consciente',
      'description': 'Aprende los fundamentos de la respiración consciente con este ejercicio de 2 minutos.',
      'isCompleted': true,
      'isLocked': false,
    },
    {
      'id': 2,
      'title': 'Respiración 4-7-8',
      'description': 'Domina la técnica de respiración 4-7-8 para calmar tu sistema nervioso.',
      'isCompleted': false,
      'isLocked': false,
    },
    {
      'id': 3,
      'title': 'Respiración Alterna',
      'description': 'Aprende a equilibrar tu energía con la respiración alterna por la nariz.',
      'isCompleted': false,
      'isLocked': true,
    },
    {
      'id': 4,
      'title': 'Respiración de Fuego',
      'description': 'Aumenta tu energía y vitalidad con la poderosa técnica de respiración de fuego.',
      'isCompleted': false,
      'isLocked': true,
    },
    {
      'id': 5,
      'title': 'Retención Avanzada',
      'description': 'Desbloquea el siguiente nivel de calma con técnicas avanzadas de retención de respiración.',
      'isCompleted': false,
      'isLocked': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    Text(
                      'Tu Camino',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Construye tu resiliencia día a día con estos ejercicios progresivos',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFFB0B0B0),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ...journeySteps.map((step) => _buildJourneyStep(context, step)),
                  ],
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomNavBar(currentIndex: 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyStep(BuildContext context, Map<String, dynamic> step) {
    final Color backgroundColor = step['isCompleted']
        ? const Color(0xFF1A392A)
        : step['isLocked']
            ? const Color(0xFF1A1F2C)
            : const Color(0xFF1A2A3C);

    final Color borderColor = step['isCompleted']
        ? const Color(0xFF00B383)
        : step['isLocked']
            ? const Color(0xFF444444)
            : const Color(0xFF336699);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          _buildStepIndicator(step),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step['title'],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: step['isLocked'] ? const Color(0xFF777777) : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step['description'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: step['isLocked'] ? const Color(0xFF666666) : const Color(0xFFB0B0B0),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildActionButton(context, step),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(Map<String, dynamic> step) {
    if (step['isCompleted']) {
      return const Icon(Icons.check_circle, color: Color(0xFF00B383), size: 32);
    } else if (step['isLocked']) {
      return const Icon(Icons.lock, color: Color(0xFF777777), size: 32);
    } else {
      return Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF336699),
        ),
        child: Center(
          child: Text(
            '${step['id']}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildActionButton(BuildContext context, Map<String, dynamic> step) {
    if (step['isCompleted']) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, color: Color(0xFF00B383), size: 20),
          const SizedBox(width: 8),
          Text(
            'Completado',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF00B383),
            ),
          ),
        ],
      );
    }

    return ElevatedButton(
      onPressed: step['isLocked'] ? null : () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: step['isLocked'] ? const Color(0xFF444444) : const Color(0xFF00B383),
        disabledBackgroundColor: const Color(0xFF444444),
        foregroundColor: Colors.white,
        disabledForegroundColor: const Color(0xFF777777),
      ),
      child: Text(step['isLocked'] ? 'Bloqueado' : 'Comenzar'),
    );
  }
} 