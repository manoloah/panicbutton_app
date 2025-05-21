import 'package:flutter/material.dart';

/// Configuration for a measurable metric in the app
class MetricConfig {
  /// Database table name for scores
  final String tableName;

  /// Database field name for the score value
  final String scoreFieldName;

  /// Display name of the metric (e.g., "BOLT")
  final String metricName;

  /// Brief description of what the metric measures
  final String metricDescription;

  /// Detailed description for the user
  final String longDescription;

  /// What the user should do at the start of the measurement
  final String measurementInstructions;

  /// What button text to show when starting measurement
  final String startButtonText;

  /// What button text to show when stopping measurement
  final String stopButtonText;

  /// List of instruction steps with their durations
  final List<MetricInstructionStep> instructionSteps;

  /// What icon or image to show for this metric
  final String instructionImage;

  /// Score zones for interpretation (what ranges mean what)
  final List<ScoreZone> scoreZones;

  /// Function to format score for display
  final String Function(int score) formatScore;

  /// Function to build the detailed instruction dialog
  final List<Widget> Function(BuildContext context) buildDetailedInstructions;

  /// Duration for the wait step (if applicable)
  final Duration defaultWaitDuration;

  /// Simplified 3-step instruction
  final List<String> simplifiedInstructions;

  /// Title displayed at the top of the screen
  final String screenTitle;

  const MetricConfig({
    required this.tableName,
    this.scoreFieldName = 'score_value',
    required this.metricName,
    required this.metricDescription,
    required this.longDescription,
    required this.measurementInstructions,
    required this.startButtonText,
    required this.stopButtonText,
    required this.instructionSteps,
    required this.instructionImage,
    required this.scoreZones,
    required this.formatScore,
    required this.buildDetailedInstructions,
    this.defaultWaitDuration = const Duration(seconds: 5),
    this.simplifiedInstructions = const [
      '1. Respira normalmente',
      '2. Pincha tu nariz',
      '3. Mide cuánto tiempo puedes aguantar'
    ],
    this.screenTitle = 'Mide tu nivel de calma',
  });
}

/// A step in the measurement instruction flow
class MetricInstructionStep {
  /// Text to display during this step
  final String instructionText;

  /// How long this step should last (null for manual progression)
  final Duration? duration;

  /// Whether this step requires breath control visualization
  final bool requiresBreathVisualization;

  /// Whether this step is an inhale step
  final bool isInhale;

  /// Whether user can manually advance this step
  final bool allowManualAdvance;

  /// Image to display during this step (null for default)
  final String? stepImage;

  const MetricInstructionStep({
    required this.instructionText,
    this.duration,
    this.requiresBreathVisualization = false,
    this.isInhale = false,
    this.allowManualAdvance = false,
    this.stepImage,
  });
}

/// A score range and its interpretation
class ScoreZone {
  /// Maximum value for this zone
  final double maxValue;

  /// Label describing this zone (e.g., "10-15 - Ansioso/Inestable")
  final String label;

  /// Description of what this zone means
  final String description;

  /// Color for this zone on charts and UI
  final Color color;

  /// Text color to use against this zone color
  final Color? textColor;

  const ScoreZone({
    required this.maxValue,
    required this.label,
    required this.description,
    required this.color,
    this.textColor,
  });
}

/// A period + its average score for any metric:
class MetricPeriodScore {
  final DateTime period;
  final double averageScore;

  const MetricPeriodScore({
    required this.period,
    required this.averageScore,
  });
}

/// Raw score record for any metric:
class MetricScore {
  final int scoreValue;
  final DateTime createdAt;

  const MetricScore({
    required this.scoreValue,
    required this.createdAt,
  });

  factory MetricScore.fromJson(Map<String, dynamic> json, String scoreField) =>
      MetricScore(
        scoreValue: json[scoreField] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
