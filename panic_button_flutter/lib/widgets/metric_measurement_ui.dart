import 'package:flutter/material.dart';
import '../models/metric_config.dart';

/// A widget that displays the measurement UI for any metric
class MetricMeasurementUI extends StatefulWidget {
  /// The metric configuration to use
  final MetricConfig metricConfig;

  /// Current score value during/after measurement
  final int score;

  /// Whether measurement is in progress
  final bool isMeasuring;

  /// Whether measurement is complete
  final bool isComplete;

  /// Whether the UI is loading
  final bool isLoading;

  /// Callback when stop button is pressed
  final VoidCallback onStop;

  /// Callback when restart button is pressed
  final VoidCallback onRestart;

  /// Callback when save button is pressed
  final VoidCallback onSave;

  /// Callback when info button is pressed
  final VoidCallback onInfoPressed;

  const MetricMeasurementUI({
    super.key,
    required this.metricConfig,
    required this.score,
    required this.isMeasuring,
    required this.isComplete,
    required this.isLoading,
    required this.onStop,
    required this.onRestart,
    required this.onSave,
    required this.onInfoPressed,
  });

  @override
  State<MetricMeasurementUI> createState() => _MetricMeasurementUIState();
}

class _MetricMeasurementUIState extends State<MetricMeasurementUI> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Get appropriate zone based on score
    ScoreZone getScoreZone(int score) {
      for (final zone in widget.metricConfig.scoreZones) {
        if (score <= zone.maxValue) {
          return zone;
        }
      }
      return widget.metricConfig.scoreZones.last;
    }

    final currentZone = getScoreZone(widget.score);

    return Column(
      children: [
        Container(
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
              // Timer display
              if (widget.isMeasuring || widget.isComplete) ...[
                Text(
                  widget.metricConfig.formatScore(widget.score),
                  style: tt.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: currentZone.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        currentZone.description,
                        style: tt.bodyMedium?.copyWith(
                          color: currentZone.color,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        Icons.info_outline,
                        color: currentZone.color,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 24, minHeight: 24),
                      onPressed: widget.onInfoPressed,
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              // Action buttons
              if (widget.isLoading) ...[
                const Center(child: CircularProgressIndicator()),
              ] else if (widget.isMeasuring) ...[
                ElevatedButton(
                  onPressed: widget.onStop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.error,
                    foregroundColor: cs.onError,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(24),
                    elevation: 4,
                    shadowColor: cs.shadow.withAlpha((0.5 * 255).toInt()),
                  ),
                  child: Text(
                    widget.metricConfig.stopButtonText,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ] else if (widget.isComplete) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: widget.onRestart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.surface,
                        foregroundColor: cs.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        elevation: 4,
                        shadowColor: cs.shadow.withAlpha((0.5 * 255).toInt()),
                        side: BorderSide(
                          color: cs.primary.withAlpha((0.4 * 255).toInt()),
                          width: 1.5,
                        ),
                      ),
                      child: const Text('Reintentar'),
                    ),
                    ElevatedButton(
                      onPressed: widget.onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primaryContainer,
                        foregroundColor: cs.onPrimaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        elevation: 4,
                        shadowColor: cs.shadow.withAlpha((0.5 * 255).toInt()),
                        side: BorderSide(
                          color: cs.primary.withAlpha((0.4 * 255).toInt()),
                          width: 1.5,
                        ),
                      ),
                      child: const Text('Guardar'),
                    ),
                  ],
                )
              ]
            ],
          ),
        ),
      ],
    );
  }
}
