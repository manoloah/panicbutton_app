import 'package:flutter/material.dart';
import '../models/metric_config.dart';
import 'bolt_metric_config.dart';

/// Registry for all available metrics in the app
///
/// HOW TO ADD A NEW METRIC:
/// 1. Create a new metric config file (e.g., my_metric_config.dart) following
///    the pattern of bolt_metric_config.dart
/// 2. Create a class with a static config getter that returns a MetricConfig
/// 3. Add the configuration to the availableMetrics list below
/// 4. Create a simple wrapper screen in the screens directory:
///
/// ```dart
/// // lib/screens/my_metric_screen.dart
/// import 'package:flutter/material.dart';
/// import '../config/my_metric_config.dart';
/// import 'metric_screen.dart';
///
/// class MyMetricScreen extends StatefulWidget {
///   const MyMetricScreen({super.key});
///
///   @override
///   State<MyMetricScreen> createState() => _MyMetricScreenState();
/// }
///
/// class _MyMetricScreenState extends State<MyMetricScreen> {
///   @override
///   Widget build(BuildContext context) {
///     return MetricScreen(
///       metricConfig: MyMetricConfig.config,
///       initialAggregation: Aggregation.week,
///     );
///   }
/// }
/// ```
///
/// 5. Add the route to main.dart (if needed)
/// 6. Create the database table for the metric scores
class MetricRegistry {
  MetricRegistry._(); // Private constructor to prevent instantiation

  /// Get all available metrics in the app
  static List<MetricConfig> get availableMetrics => [
        BoltMetricConfig.config,
        // Add more metrics here as they become available
      ];

  /// Find a metric by name
  static MetricConfig? findByName(String name) {
    try {
      return availableMetrics.firstWhere(
          (metric) => metric.metricName.toLowerCase() == name.toLowerCase());
    } catch (_) {
      debugPrint('Metric not found: $name');
      return null;
    }
  }

  /// Get icon for metric by name
  static IconData getIconForMetric(String metricName) {
    switch (metricName.toUpperCase()) {
      case 'BOLT':
        return Icons.psychology;
      case 'MBT':
        return Icons.air;
      default:
        return Icons.show_chart;
    }
  }
}
