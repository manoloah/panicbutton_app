import 'package:flutter/material.dart';
import '../models/metric_config.dart';

class MetricMeasurementUI extends StatelessWidget {
  final MetricConfig metricConfig;
  final bool isMeasuring;
  final bool isComplete;
  final int seconds;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onRestart;
  final VoidCallback onSave;
  final VoidCallback onShowInfoDialog;

  const MetricMeasurementUI({
    super.key,
    required this.metricConfig,
    required this.isMeasuring,
    required this.isComplete,
    required this.seconds,
    required this.onStart,
    required this.onStop,
    required this.onRestart,
    required this.onSave,
    required this.onShowInfoDialog,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Get state color and description from the metric config
    final stateColor = metricConfig.getScoreColor(seconds);
    final stateDescription = metricConfig.getScoreDescription(seconds);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Use minimum required space
        children: [
          Text(
            isMeasuring
                ? 'Detén al primer deseo de respirar'
                : isComplete
                    ? metricConfig.resultTitle
                        .replaceFirst('%s', seconds.toString())
                    : 'Presiona para empezar',
            style: tt.headlineMedium,
            textAlign: TextAlign.center,
          ),
          if (isComplete) ...[
            const SizedBox(height: 8),
            Text(
              'Lo hicistes bien si después de retener lograste respirar normal y de forma controlada como empezaste',
              style: tt.bodySmall,
              textAlign: TextAlign.center,
            ),
            // Mental state description
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: stateColor.withAlpha((0.15 * 255).toInt()),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: stateColor.withAlpha((0.5 * 255).toInt()),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.1 * 255).toInt()),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '¿Qué significa tu score?',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: stateColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          stateDescription,
                          style: tt.bodyMedium?.copyWith(
                            color: stateColor,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(
                          Icons.info_outline,
                          color: stateColor,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 24, minHeight: 24),
                        onPressed: onShowInfoDialog,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (isMeasuring) ...[
            Container(
              constraints:
                  const BoxConstraints(maxHeight: 140), // Constrain height
              child: Column(
                mainAxisSize: MainAxisSize.min, // Use minimum space
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$seconds',
                    style: tt.displayLarge?.copyWith(
                      fontSize: 60, // Reduced from 64
                      height: 0.9, // Tighter line height
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'segundos',
                    style: tt.headlineSmall?.copyWith(
                      color: cs.onSurface.withAlpha((0.8 * 255).toInt()),
                      fontSize: 18, // Smaller text
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16), // Reduced from 20
            Padding(
              padding: const EdgeInsets.only(bottom: 8), // Added bottom padding
              child: ElevatedButton(
                onPressed: onStop,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4500), // Error color
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  elevation: 4,
                  shadowColor: Colors.red.withAlpha((0.5 * 255).toInt()),
                  side: BorderSide(
                    color: Colors.red.withAlpha((0.4 * 255).toInt()),
                    width: 1.5,
                  ),
                ),
                child: const Text('DETENER'),
              ),
            ),
          ] else if (isComplete) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: onRestart, // Use new restart method
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
                  onPressed: onSave,
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
          ] else ...[
            ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primaryContainer,
                foregroundColor: cs.onPrimaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                elevation: 4,
                shadowColor: cs.shadow.withAlpha((0.5 * 255).toInt()),
                side: BorderSide(
                  color: cs.primary.withAlpha((0.4 * 255).toInt()),
                  width: 1.5,
                ),
              ),
              child: const Text('EMPEZAR'),
            ),
          ],
        ],
      ),
    );
  }
}
