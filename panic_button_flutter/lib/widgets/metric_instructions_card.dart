import 'package:flutter/material.dart';
import '../models/metric_config.dart';

/// A widget that displays instructions for a metric measurement
class MetricInstructionsCard extends StatelessWidget {
  /// The metric configuration
  final MetricConfig metricConfig;

  /// Callback when the start button is pressed
  final VoidCallback onStart;

  const MetricInstructionsCard({
    super.key,
    required this.metricConfig,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
      ),
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
                      metricConfig.displayName,
                      style: tt.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metricConfig.recommendationText,
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
                onPressed: () {
                  // Show detailed instructions in a dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Instrucciones Detalladas'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: metricConfig.enhancedInstructions
                              .map((step) =>
                                  _buildEnhancedInstructionStep(context, step))
                              .toList(),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Compact instruction steps
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Step 1
              _buildCompactStepFromConfig(cs, metricConfig.compactSteps[0]),

              // Arrow
              Icon(Icons.arrow_forward,
                  color: cs.onSurface.withAlpha((0.5 * 255).toInt())),

              // Step 2
              _buildCompactStepFromConfig(cs, metricConfig.compactSteps[1]),

              // Arrow
              Icon(Icons.arrow_forward,
                  color: cs.onSurface.withAlpha((0.5 * 255).toInt())),

              // Step 3
              _buildCompactStepFromConfig(cs, metricConfig.compactSteps[2]),
            ],
          ),

          const SizedBox(height: 16),

          // Start button
          ElevatedButton(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              elevation: 4,
              shadowColor: cs.shadow.withAlpha((0.4 * 255).toInt()),
              side: BorderSide(
                color: cs.primary.withAlpha((0.4 * 255).toInt()),
                width: 1.5,
              ),
              minimumSize:
                  const Size(double.infinity, 48), // Make button full width
            ),
            child: const Text('COMENZAR'),
          ),
        ],
      ),
    );
  }

  // Helper method to build a compact step from config
  Widget _buildCompactStepFromConfig(
      ColorScheme cs, MetricInstructionStep step) {
    if (step.icon != null) {
      return _buildCompactStep(cs, step.icon!, step.description);
    } else if (step.imagePath != null) {
      return _buildCompactStepWithImage(cs, step.imagePath!, step.description);
    } else {
      // Default to a placeholder icon if neither is provided
      return _buildCompactStep(cs, Icons.help_outline, step.description);
    }
  }

  // Helper method for compact step display with icon
  Widget _buildCompactStep(ColorScheme cs, IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: const Color(0xFFB0B0B0), // _altText from app_theme.dart
          size: 30,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }

  // Helper method for compact step using image instead of icon
  Widget _buildCompactStepWithImage(
      ColorScheme cs, String imagePath, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          imagePath,
          width: 30,
          height: 30,
          color: const Color(0xFFB0B0B0), // _altText from app_theme.dart
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }

  // Helper method to build instruction steps for the detailed dialog
  Widget _buildEnhancedInstructionStep(
      BuildContext context, EnhancedInstructionStep step) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step.stepNumber.toString(),
                style: tt.bodySmall?.copyWith(color: cs.onPrimary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${step.mainText}. ${step.supportText}',
              style: tt.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
