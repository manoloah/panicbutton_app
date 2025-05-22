// lib/screens/bolt_screen.dart

import 'package:flutter/material.dart';
import '../screens/metric_screen.dart';
import '../constants/metric_configs.dart';

/// Screen for measuring the BOLT (Body Oxygen Level Test) metric
class BoltScreen extends StatelessWidget {
  const BoltScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use the generic MetricScreen with the BOLT configuration
    return MetricScreen(
      metricConfig: MetricConfigs.boltConfig,
      navbarIndex: 2, // Index for the BOLT tab in the navbar
    );
  }
}
