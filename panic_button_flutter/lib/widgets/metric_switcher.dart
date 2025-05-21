import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/metric_config.dart';
import '../config/metric_registry.dart';

/// A widget for switching between different metrics
class MetricSwitcher extends StatelessWidget {
  /// The current metric config - used to highlight the active metric
  final MetricConfig currentMetric;

  const MetricSwitcher({
    super.key,
    required this.currentMetric,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Use the metrics from the registry
    final availableMetrics = MetricRegistry.availableMetrics;

    return Column(
      children: [
        Text(
          availableMetrics.length > 1
              ? 'Métricas disponibles:'
              : 'Métrica disponible:',
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        // Horizontally scrollable row of metric buttons
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: availableMetrics
                .map((metric) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: _buildMetricButton(
                        context,
                        metric.metricName,
                        '/${metric.metricName.toLowerCase()}',
                        currentMetric.metricName == metric.metricName,
                        MetricRegistry.getIconForMetric(metric.metricName),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricButton(
    BuildContext context,
    String label,
    String route,
    bool isActive,
    IconData icon,
  ) {
    final cs = Theme.of(context).colorScheme;

    return ElevatedButton.icon(
      onPressed: isActive ? null : () => context.go(route),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? cs.primaryContainer : cs.surface,
        foregroundColor: isActive ? cs.onPrimaryContainer : cs.primary,
        disabledBackgroundColor: cs.primaryContainer,
        disabledForegroundColor: cs.onPrimaryContainer,
        elevation: isActive ? 0 : 2,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isActive ? Colors.transparent : cs.primary.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
