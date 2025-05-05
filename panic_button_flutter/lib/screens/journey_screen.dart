import 'package:flutter/material.dart';
import 'package:panic_button_flutter/widgets/custom_nav_bar.dart';

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  final journeySteps = const [
    {
      'id': 1,
      'title': 'Respiración Consciente',
      'description':
          'Aprende los fundamentos de la respiración consciente con este ejercicio de 2 minutos.',
      'isCompleted': true,
      'isLocked': false,
    },
    {
      'id': 2,
      'title': 'Respiración 4-7-8',
      'description':
          'Domina la técnica de respiración 4-7-8 para calmar tu sistema nervioso.',
      'isCompleted': false,
      'isLocked': false,
    },
    {
      'id': 3,
      'title': 'Respiración Alterna',
      'description':
          'Aprende a equilibrar tu energía con la respiración alterna por la nariz.',
      'isCompleted': false,
      'isLocked': true,
    },
    {
      'id': 4,
      'title': 'Respiración de Fuego',
      'description':
          'Aumenta tu energía y vitalidad con la poderosa técnica de respiración de fuego.',
      'isCompleted': false,
      'isLocked': true,
    },
    {
      'id': 5,
      'title': 'Retención Avanzada',
      'description':
          'Desbloquea el siguiente nivel de calma con técnicas avanzadas de retención de respiración.',
      'isCompleted': false,
      'isLocked': true,
    },
  ];

  int? expandedStepId;

  void _toggleExpandStep(int id) {
    setState(() {
      expandedStepId = expandedStepId == id ? null : id;
    });
  }

  void _startExercise(Map<String, dynamic> step) {
    // Here we would navigate to the relevant breathing exercise
    // For now, just print to console
    print('Starting exercise: ${step['title']}');
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      // Explicitly set no resizeToAvoidBottomInset to prevent keyboard issues
      resizeToAvoidBottomInset: false,
      // Use a Column to ensure proper layout
      body: Column(
        children: [
          // Main content area - takes most of the screen
          Expanded(
            child: SafeArea(
              bottom: false, // Don't add safe area at bottom
              child: Stack(
                children: [
                  // Scrollable content
                  SingleChildScrollView(
                    padding: EdgeInsets.only(
                        bottom: 80 +
                            bottomPadding), // Adjust padding for nav bar height
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 32),
                          Text(
                            'Tu Camino',
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge
                                ?.copyWith(
                                  fontSize: 32,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Construye tu resiliencia día a día con estos ejercicios progresivos',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: const Color(0xFFB0B0B0),
                                    ),
                          ),
                          const SizedBox(height: 32),
                          // Journey path with timeline
                          _buildJourneyPath(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom navigation - fixed at the bottom with no extra space
          const CustomNavBar(
            currentIndex: 0,
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyPath(BuildContext context) {
    return Column(
      children: List.generate(journeySteps.length, (index) {
        final step = journeySteps[index];
        final isLastStep = index == journeySteps.length - 1;
        final isExpanded = expandedStepId == step['id'];

        return Column(
          children: [
            _buildJourneyStep(context, step, isExpanded),
            // Don't add the connector after the last step
            if (!isLastStep)
              _buildConnector(step['isCompleted'] == true, index),
          ],
        );
      }),
    );
  }

  Widget _buildConnector(bool isCompleted, int index) {
    // Calculate how many steps are locked before this one
    int lockedStepsBeforeThis = 0;
    for (int i = 0; i <= index; i++) {
      if (journeySteps[i]['isLocked'] == true) {
        lockedStepsBeforeThis++;
      }
    }

    return Container(
      margin: const EdgeInsets.only(left: 16),
      height: 30,
      width: 2,
      decoration: BoxDecoration(
        gradient: lockedStepsBeforeThis > 0
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  isCompleted
                      ? const Color(0xFF00B383)
                      : const Color(0xFF336699),
                  const Color(0xFF444444),
                ],
              ),
        color: lockedStepsBeforeThis > 0 ? const Color(0xFF444444) : null,
      ),
    );
  }

  Widget _buildJourneyStep(
      BuildContext context, Map<String, dynamic> step, bool isExpanded) {
    final Color backgroundColor = step['isCompleted'] == true
        ? const Color(0xFF1A392A)
        : step['isLocked'] == true
            ? const Color(0xFF1A1F2C)
            : const Color(0xFF1A2A3C);

    final Color borderColor = step['isCompleted'] == true
        ? const Color(0xFF00B383)
        : step['isLocked'] == true
            ? const Color(0xFF444444)
            : const Color(0xFF336699);

    return GestureDetector(
      onTap: step['isLocked'] == true
          ? null
          : () => _toggleExpandStep(step['id'] as int),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: isExpanded
              ? [
                  BoxShadow(
                    color: borderColor.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                _buildStepIndicator(step),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['title'] as String,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: step['isLocked'] == true
                                      ? const Color(0xFF777777)
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step['description'] as String,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: step['isLocked'] == true
                                  ? const Color(0xFF666666)
                                  : const Color(0xFFB0B0B0),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _buildActionButton(context, step),
              ],
            ),

            // Expanded content
            if (isExpanded && step['isLocked'] != true)
              _buildExpandedContent(context, step),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(
      BuildContext context, Map<String, dynamic> step) {
    final Color textColor = step['isCompleted'] == true
        ? const Color(0xFFBBFFE7)
        : const Color(0xFFB0D0FF);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise details
          Row(
            children: [
              Icon(
                step['isCompleted'] == true
                    ? Icons.timer_outlined
                    : Icons.directions_run,
                color: textColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Duración: 2-5 minutos',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Benefits
          Row(
            children: [
              Icon(
                Icons.favorite_outline,
                color: textColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Beneficios:',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              _getBenefitsText(step['id'] as int),
              style: TextStyle(
                color: textColor,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(height: 16),
          // Start button
          if (step['isCompleted'] != true)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _startExercise(step),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B383),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Comenzar Ejercicio'),
              ),
            ),
          if (step['isCompleted'] == true)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _startExercise(step),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00B383),
                  side: const BorderSide(color: Color(0xFF00B383)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Repetir Ejercicio'),
              ),
            ),
        ],
      ),
    );
  }

  String _getBenefitsText(int stepId) {
    switch (stepId) {
      case 1:
        return 'Reduce el estrés, mejora la concentración y disminuye la ansiedad en momentos difíciles.';
      case 2:
        return 'Calma el sistema nervioso, reduce la frecuencia cardíaca y ayuda a manejar episodios de pánico.';
      case 3:
        return 'Equilibra los hemisferios cerebrales, promueve la claridad mental y el equilibrio emocional.';
      case 4:
        return 'Energiza rápidamente, aumenta la vitalidad y activa el metabolismo.';
      case 5:
        return 'Mejora la resistencia al estrés, aumenta la capacidad pulmonar y fortalece el sistema inmunológico.';
      default:
        return 'Mejora tu bienestar general con esta práctica.';
    }
  }

  Widget _buildStepIndicator(Map<String, dynamic> step) {
    if (step['isCompleted'] == true) {
      return const Icon(Icons.check_circle, color: Color(0xFF00B383), size: 32);
    } else if (step['isLocked'] == true) {
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
    if (step['isCompleted'] == true) {
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
      onPressed: step['isLocked'] == true ? null : () => _startExercise(step),
      style: ElevatedButton.styleFrom(
        backgroundColor: step['isLocked'] == true
            ? const Color(0xFF444444)
            : const Color(0xFF00B383),
        disabledBackgroundColor: const Color(0xFF444444),
        foregroundColor: Colors.white,
        disabledForegroundColor: const Color(0xFF777777),
      ),
      child: Text(step['isLocked'] == true ? 'Bloqueado' : 'Comenzar'),
    );
  }
}
