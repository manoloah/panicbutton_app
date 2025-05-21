import 'package:flutter/material.dart';
import '../widgets/breath_circle.dart';
import '../widgets/wave_animation.dart';
import '../models/metric_config.dart';

/// An overlay widget that displays step-by-step instructions for a metric
class MetricInstructionOverlay extends StatelessWidget {
  /// The current instruction step
  final int instructionStep;

  /// The instruction steps
  final List<MetricInstructionStep> instructions;

  /// The countdown for timed steps
  final int instructionCountdown;

  /// Callback when the overlay is closed
  final VoidCallback onClose;

  /// Callback to proceed to next instruction
  final VoidCallback onNext;

  /// Callback to start measurement
  final VoidCallback onStartMeasurement;

  /// Animation controller for breath animations
  final Animation<double> breathAnimation;

  const MetricInstructionOverlay({
    super.key,
    required this.instructionStep,
    required this.instructions,
    required this.instructionCountdown,
    required this.onClose,
    required this.onNext,
    required this.onStartMeasurement,
    required this.breathAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withAlpha((0.9 * 255).toInt()), // Dim background
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  // Header with close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: onClose,
                      ),
                    ],
                  ),

                  // Instruction animation - takes most of the screen
                  Expanded(
                    child: _buildInstructionContent(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionContent(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Get the current instruction
    final currentInstruction = instructionStep < instructions.length
        ? instructions[instructionStep]
        : null;

    String phaseText = currentInstruction?.description ?? '';
    String? instructionImage = currentInstruction?.imagePath;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title
          Text(
            phaseText,
            style: tt.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          // Main content
          Expanded(
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildStepContent(
                  context,
                  currentInstruction,
                  instructionImage,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    MetricInstructionStep? currentStep,
    String? instructionImage,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Initial instruction step (preparation)
    if (instructionStep == 0) {
      return Column(
        key: const ValueKey('step0'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (instructionImage != null)
            Image.asset(
              instructionImage,
              width: 100,
              height: 100,
              color: cs.primary,
            )
          else if (currentStep?.icon != null)
            Icon(
              currentStep!.icon,
              size: 100,
              color: cs.primary,
            ),
          const SizedBox(height: 20),
          Text(
            'Preparate para hacer una inhalación normal',
            style: tt.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              elevation: 4,
              shadowColor: cs.shadow.withAlpha((0.5 * 255).toInt()),
              side: BorderSide(
                color: cs.primary.withAlpha((0.4 * 255).toInt()),
                width: 1.5,
              ),
            ),
            child: const Text('SIGUIENTE'),
          ),
        ],
      );
    }
    // Timed steps (inhale/exhale)
    else if (currentStep?.isTimedStep == true) {
      return Column(
        key: ValueKey('step$instructionStep'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Countdown
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: cs.primary.withAlpha((0.2 * 255).toInt()),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              instructionCountdown.toString(),
              style: tt.displayLarge?.copyWith(
                color: cs.primary,
                fontSize: 48,
              ),
            ),
          ),

          // Circle
          BreathCircle(
            isBreathing: true,
            onTap: () {},
            size: 150, // Smaller size
            phaseIndicator: WaveAnimation(
              waveAnimation: breathAnimation,
              fillLevel: instructionStep % 2 == 1
                  ? breathAnimation.value
                  : 1 - breathAnimation.value,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            instructionStep % 2 == 1
                ? 'Preparate para exhalar...'
                : 'Preparate para retener...',
            style: tt.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    // Final step (pinch nose / start)
    else {
      return Column(
        key: const ValueKey('step_final'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (instructionImage != null)
            Image.asset(
              instructionImage,
              width: 100,
              height: 100,
            )
          else if (currentStep?.icon != null)
            Icon(
              currentStep!.icon,
              size: 100,
              color: cs.primary,
            ),
          const SizedBox(height: 20),
          Text(
            'Cuando estés listo para comenzar la retención, presiona el botón:',
            style: tt.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onStartMeasurement,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              elevation: 4,
              shadowColor: cs.shadow.withAlpha((0.5 * 255).toInt()),
              side: BorderSide(
                color: cs.primary.withAlpha((0.4 * 255).toInt()),
                width: 1.5,
              ),
            ),
            child: const Text('EMPEZAR MEDICIÓN'),
          ),
        ],
      );
    }
  }
}
