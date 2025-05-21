import 'package:flutter/material.dart';
import '../models/metric_config.dart';
import '../widgets/breath_circle.dart';

/// A widget that displays the instruction overlay for any metric
class MetricInstructionOverlay extends StatefulWidget {
  /// The metric configuration to use
  final MetricConfig metricConfig;

  /// Current instruction step
  final int instructionStep;

  /// Countdown value for timed steps (in seconds)
  final double countdownValue;

  /// Callback when close button is pressed
  final VoidCallback onClose;

  /// Callback when manual advance is requested
  final VoidCallback onManualAdvance;

  const MetricInstructionOverlay({
    super.key,
    required this.metricConfig,
    required this.instructionStep,
    required this.countdownValue,
    required this.onClose,
    required this.onManualAdvance,
  });

  @override
  State<MetricInstructionOverlay> createState() =>
      _MetricInstructionOverlayState();
}

class _MetricInstructionOverlayState extends State<MetricInstructionOverlay> {
  @override
  Widget build(BuildContext context) {
    // Safety check to avoid index errors
    if (widget.instructionStep >= widget.metricConfig.instructionSteps.length) {
      return const SizedBox.shrink();
    }

    final step = widget.metricConfig.instructionSteps[widget.instructionStep];
    final cs = Theme.of(context).colorScheme;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withAlpha((0.9 * 255).toInt()), // Dim background
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Material(
              color: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header with close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),

                  // Instruction animation - takes most of the screen
                  Expanded(
                    child: _buildInstructionContent(step),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionContent(MetricInstructionStep step) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Use specified image or default
        if (step.stepImage != null) ...[
          Expanded(
            child: Center(
              child: Image.asset(
                step.stepImage!,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ]
        // Show breath animation for inhale/exhale
        else if (step.requiresBreathVisualization) ...[
          Expanded(
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(20),
                child: BreathCircle(
                  isBreathing: true,
                  onTap:
                      () {}, // Empty callback since we don't need interaction here
                  size: 150, // Smaller size for instruction overlay
                ),
              ),
            ),
          ),
        ]
        // Default to centered instruction text
        else ...[
          Expanded(
            child: Center(
              child: Image.asset(
                widget.metricConfig.instructionImage,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],

        // Instruction text
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(26), // 10% white
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            step.instructionText,
            style: tt.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 24),

        // Countdown or Continue button
        if (step.duration != null) ...[
          // Show countdown for timed steps
          RichText(
            text: TextSpan(
              text: 'Tiempo restante: ',
              style: tt.bodyLarge?.copyWith(color: Colors.white70),
              children: [
                TextSpan(
                  text: '${widget.countdownValue.toInt()} segundos',
                  style: tt.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ] else if (step.allowManualAdvance) ...[
          // Show continue button for manual advance steps
          ElevatedButton(
            onPressed: widget.onManualAdvance,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              elevation: 4,
              shadowColor: cs.shadow.withAlpha((0.5 * 255).toInt()),
            ),
            child: Text(
              'Continuar',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
