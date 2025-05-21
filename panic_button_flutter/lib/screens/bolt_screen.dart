// lib/screens/bolt_screen.dart

import 'package:flutter/material.dart';
import '../config/bolt_metric_config.dart';
import 'metric_screen.dart';

/// Screen for BOLT (Body Oxygen Level Test) measurement
class BoltScreen extends StatefulWidget {
  const BoltScreen({super.key});

  @override
  State<BoltScreen> createState() => _BoltScreenState();
}

class _BoltScreenState extends State<BoltScreen> {
  @override
  Widget build(BuildContext context) {
    // Use the generic MetricScreen with the BOLT configuration
    return MetricScreen(
      metricConfig: BoltMetricConfig.config,
      initialAggregation: Aggregation.week,
    );
  }
}
