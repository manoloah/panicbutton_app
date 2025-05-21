import 'package:flutter/material.dart';
import '../config/mbt_metric_config.dart';
import 'metric_screen.dart';

/// Screen for MBT (Maximum Breath Time) measurement
class MbtScreen extends StatefulWidget {
  const MbtScreen({super.key});

  @override
  State<MbtScreen> createState() => _MbtScreenState();
}

class _MbtScreenState extends State<MbtScreen> {
  @override
  Widget build(BuildContext context) {
    // Use the generic MetricScreen with the MBT configuration
    return MetricScreen(
      metricConfig: MbtMetricConfig.config,
      initialAggregation: Aggregation.week,
    );
  }
}
