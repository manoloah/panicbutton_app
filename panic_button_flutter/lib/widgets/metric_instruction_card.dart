import 'package:flutter/material.dart';
import '../models/metric_config.dart';

/// A widget that displays the instruction card for a metric
class MetricInstructionCard extends StatelessWidget {
  /// The metric configuration to use
  final MetricConfig metricConfig;

  /// Callback when start button is pressed
  final VoidCallback onStart;

  /// Callback when info button is pressed
  final VoidCallback onInfoPressed;

  const MetricInstructionCard({
    super.key,
    required this.metricConfig,
    required this.onStart,
    required this.onInfoPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withAlpha(77), // ~0.3 opacity
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metricConfig.metricName,
                      style: tt.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metricConfig.measurementInstructions,
                      style: tt.bodySmall,
                    ),
                  ],
                ),
              ),
              // Info button
              IconButton(
                icon: Icon(
                  Icons.info_outline,
                  color: cs.primary,
                ),
                onPressed: onInfoPressed,
              ),
            ],
          ),

          const SizedBox(height: 16),

          Image.asset(
            metricConfig.instructionImage,
            height: 160,
            fit: BoxFit.contain,
          ),

          const SizedBox(height: 16),

          Text(
            metricConfig.metricDescription,
            style: tt.bodyMedium,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Simplified instructions
          Container(
            decoration: BoxDecoration(
              color: cs.surface.withAlpha(128),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: cs.outlineVariant,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instrucciones rápidas:',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...metricConfig.simplifiedInstructions
                    .map((instruction) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            instruction,
                            style: tt.bodyMedium,
                          ),
                        )),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Start button
          ElevatedButton(
            onPressed: onStart,
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
              metricConfig.startButtonText,
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
