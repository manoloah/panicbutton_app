import 'package:flutter/material.dart';

/// A zone configuration for a specific score range in the chart
class MetricScoreZone {
  final double lowerBound;
  final double upperBound;
  final String label;
  final Color color;

  const MetricScoreZone({
    required this.lowerBound,
    required this.upperBound,
    required this.label,
    required this.color,
  });
}

/// Enhanced instruction step that matches the CSV structure with all 5 parts
class EnhancedInstructionStep {
  final int stepNumber;
  final String mainText;
  final String supportText;
  final String callToActionText;
  final IconData? icon;
  final String? imagePath;
  final bool movesToNextStepAutomatically;
  final String nextStepPrepText;
  final bool isTimedStep;
  final int? durationSeconds;

  const EnhancedInstructionStep({
    required this.stepNumber,
    required this.mainText,
    required this.supportText,
    required this.callToActionText,
    this.icon,
    this.imagePath,
    required this.movesToNextStepAutomatically,
    required this.nextStepPrepText,
    this.isTimedStep = false,
    this.durationSeconds,
  });
}

/// Instructions for a metric measurement step
class MetricInstructionStep {
  final int stepNumber;
  final String description;
  final IconData? icon;
  final String? imagePath;
  final bool isTimedStep;
  final int? durationSeconds;

  const MetricInstructionStep({
    required this.stepNumber,
    required this.description,
    this.icon,
    this.imagePath,
    this.isTimedStep = false,
    this.durationSeconds,
  });
}

/// Configuration for a metric measurement
class MetricConfig {
  /// The unique identifier for this metric type
  final String id;

  /// The display name of the metric
  final String displayName;

  /// The database table name where this metric's scores are stored
  final String tableName;

  /// Short display name for charts and labels
  final String shortName;

  /// Description explaining what the metric measures
  final String description;

  /// The chart title for this metric
  final String chartTitle;

  /// The title shown when viewing the score result
  final String resultTitle;

  /// The field name in the database where the score is stored
  final String scoreFieldName;

  /// The recommendation text for when to measure this metric
  final String recommendationText;

  /// The zones for score visualization in the chart
  final List<MetricScoreZone> scoreZones;

  /// The enhanced instruction steps with all 5 parts from CSV
  final List<EnhancedInstructionStep> enhancedInstructions;

  /// The compact instruction steps for summary view
  final List<MetricInstructionStep> compactSteps;

  /// Function to get a description of what a particular score means
  final String Function(int score) getScoreDescription;

  /// Function to get the color associated with a score
  final Color Function(int score) getScoreColor;

  const MetricConfig({
    required this.id,
    required this.displayName,
    required this.tableName,
    required this.shortName,
    required this.description,
    required this.chartTitle,
    required this.resultTitle,
    required this.scoreFieldName,
    required this.recommendationText,
    required this.scoreZones,
    required this.enhancedInstructions,
    required this.compactSteps,
    required this.getScoreDescription,
    required this.getScoreColor,
  });
}
