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
    final screenHeight = MediaQuery.of(context).size.height;

    // Get the current instruction (adjust for 0-based indexing)
    final currentInstruction =
        instructionStep > 0 && instructionStep <= instructions.length
            ? instructions[instructionStep - 1]
            : null;

    String phaseText = currentInstruction?.description ?? '';
    String? instructionImage = currentInstruction?.imagePath;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.8, // Limit height to prevent overflow
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: 16.0, vertical: 20.0), // Reduced padding
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title - more compact
          Text(
            phaseText,
            style: tt.headlineSmall, // Smaller title
            textAlign: TextAlign.center,
            maxLines: 3, // Allow more lines for longer text
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20), // Reduced spacing

          // Main content - use Flexible instead of Expanded to prevent overflow
          Flexible(
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
        mainAxisSize: MainAxisSize.min, // Use minimum space
        children: [
          if (instructionImage != null)
            Image.asset(
              instructionImage,
              width: 80, // Smaller image
              height: 80,
              color: cs.primary,
            )
          else if (currentStep?.icon != null)
            Icon(
              currentStep!.icon,
              size: 80, // Smaller icon
              color: cs.primary,
            ),
          const SizedBox(height: 16), // Reduced spacing
          Text(
            'Preparate para hacer una inhalación normal',
            style: tt.bodyMedium,
            textAlign: TextAlign.center,
            maxLines: 2, // Limit lines
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16), // Reduced spacing
          ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), // Smaller radius
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 10), // Smaller padding
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
    // Timed steps (inhale/exhale) - steps 1 and 2
    else if (instructionStep <= 2 && currentStep?.isTimedStep == true) {
      return Column(
        key: ValueKey('step$instructionStep'),
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Use minimum space
        children: [
          // Countdown - more compact
          Container(
            margin: const EdgeInsets.only(bottom: 12), // Reduced margin
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 6), // Smaller padding
            decoration: BoxDecoration(
              color: cs.primary.withAlpha((0.2 * 255).toInt()),
              borderRadius: BorderRadius.circular(12), // Smaller radius
            ),
            child: Text(
              instructionCountdown.toString(),
              style: tt.displayMedium?.copyWith(
                // Smaller font
                color: cs.primary,
                fontSize: 36, // Reduced from 48
              ),
            ),
          ),

          // Circle - smaller
          BreathCircle(
            isBreathing: true,
            onTap: () {},
            size: 120, // Smaller size
            phaseIndicator: WaveAnimation(
              waveAnimation: breathAnimation,
              fillLevel: instructionStep % 2 == 1
                  ? breathAnimation.value
                  : 1 - breathAnimation.value,
            ),
          ),
          const SizedBox(height: 12), // Reduced spacing
          Text(
            instructionStep % 2 == 1 ? 'Inhala NORMAL...' : 'Exhala NORMAL...',
            style: tt.bodyMedium,
            textAlign: TextAlign.center,
            maxLines: 1, // Limit lines
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }
    // Step 3: Pinch nose
    else if (instructionStep == 3) {
      return Column(
        key: const ValueKey('step3'),
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Use minimum space
        children: [
          if (instructionImage != null)
            Image.asset(
              instructionImage,
              width: 80, // Smaller image
              height: 80,
            )
          else if (currentStep?.icon != null)
            Icon(
              currentStep!.icon,
              size: 80, // Smaller icon
              color: cs.primary,
            ),
          const SizedBox(height: 16), // Reduced spacing
          Text(
            'Pincha tu nariz y retén la respiración',
            style: tt.bodyMedium,
            textAlign: TextAlign.center,
            maxLines: 3, // Limit lines
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16), // Reduced spacing
          ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), // Smaller radius
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 10), // Smaller padding
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
    // Step 4: Walk counting steps
    else {
      return Column(
        key: const ValueKey('step4'),
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Use minimum space
        children: [
          if (instructionImage != null)
            Image.asset(
              instructionImage,
              width: 80, // Smaller image
              height: 80,
            )
          else if (currentStep?.icon != null)
            Icon(
              currentStep!.icon,
              size: 80, // Smaller icon
              color: cs.primary,
            ),
          const SizedBox(height: 16), // Reduced spacing
          Text(
            'Camina contando tus pasos hasta llegar al máximo',
            style: tt.bodyMedium,
            textAlign: TextAlign.center,
            maxLines: 3, // Limit lines
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16), // Reduced spacing
          ElevatedButton(
            onPressed: onStartMeasurement,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), // Smaller radius
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 10), // Smaller padding
              elevation: 4,
              shadowColor: cs.shadow.withAlpha((0.5 * 255).toInt()),
              side: BorderSide(
                color: cs.primary.withAlpha((0.4 * 255).toInt()),
                width: 1.5,
              ),
            ),
            child: const Text('REGISTRA PASOS'),
          ),
        ],
      );
    }
  }
}
