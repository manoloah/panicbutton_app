// Basic models for the breathing features
// Using plain Dart classes instead of freezed models to avoid generation issues

import 'package:flutter/foundation.dart';

// Step model representing a single breathing step
class StepModel {
  final String id;
  final int inhaleSecs;
  final String inhaleMethod;
  final int holdInSecs;
  final int exhaleSecs;
  final String exhaleMethod;
  final int holdOutSecs;
  final String? cueText;
  final DateTime? createdAt;

  const StepModel({
    this.id = '',
    this.inhaleSecs = 4,
    this.inhaleMethod = 'nose',
    this.holdInSecs = 0,
    this.exhaleSecs = 4,
    this.exhaleMethod = 'nose',
    this.holdOutSecs = 0,
    this.cueText = 'Respira',
    this.createdAt,
  });

  factory StepModel.fromJson(Map<String, dynamic> json) {
    return StepModel(
      id: json['id'] as String? ?? '',
      inhaleSecs: json['inhale_secs'] as int? ?? 4,
      inhaleMethod: json['inhale_method'] as String? ?? 'nose',
      holdInSecs: json['hold_in_secs'] as int? ?? 0,
      exhaleSecs: json['exhale_secs'] as int? ?? 4,
      exhaleMethod: json['exhale_method'] as String? ?? 'nose',
      holdOutSecs: json['hold_out_secs'] as int? ?? 0,
      cueText: json['cue_text'] as String? ?? 'Respira',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inhale_secs': inhaleSecs,
      'inhale_method': inhaleMethod,
      'hold_in_secs': holdInSecs,
      'exhale_secs': exhaleSecs,
      'exhale_method': exhaleMethod,
      'hold_out_secs': holdOutSecs,
      'cue_text': cueText,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StepModel &&
        other.id == id &&
        other.inhaleSecs == inhaleSecs &&
        other.inhaleMethod == inhaleMethod &&
        other.holdInSecs == holdInSecs &&
        other.exhaleSecs == exhaleSecs &&
        other.exhaleMethod == exhaleMethod &&
        other.holdOutSecs == holdOutSecs &&
        other.cueText == cueText;
  }

  @override
  int get hashCode => Object.hash(
        id,
        inhaleSecs,
        inhaleMethod,
        holdInSecs,
        exhaleSecs,
        exhaleMethod,
        holdOutSecs,
        cueText,
      );
}

// Pattern step model for a step within a pattern
class PatternStepModel {
  final String id;
  final String patternId;
  final String stepId;
  final int position;
  final int repetitions;
  final DateTime? createdAt;
  final StepModel? step;

  const PatternStepModel({
    this.id = '',
    this.patternId = '',
    this.stepId = '',
    this.position = 0,
    this.repetitions = 1,
    this.createdAt,
    this.step,
  });

  factory PatternStepModel.fromJson(Map<String, dynamic> json) {
    return PatternStepModel(
      id: json['id'] as String? ?? '',
      patternId: json['pattern_id'] as String? ?? '',
      stepId: json['step_id'] as String? ?? '',
      position: json['position'] as int? ?? 0,
      repetitions: json['repetitions'] as int? ?? 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      step: json['step'] != null
          ? StepModel.fromJson(json['step'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pattern_id': patternId,
      'step_id': stepId,
      'position': position,
      'repetitions': repetitions,
      'created_at': createdAt?.toIso8601String(),
      'step': step?.toJson(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PatternStepModel &&
        other.id == id &&
        other.patternId == patternId &&
        other.stepId == stepId &&
        other.position == position &&
        other.repetitions == repetitions &&
        other.step == step;
  }

  @override
  int get hashCode => Object.hash(
        id,
        patternId,
        stepId,
        position,
        repetitions,
        step,
      );
}

// Pattern model for a breathing pattern
class PatternModel {
  final String id;
  final String name;
  final String goalId;
  final int recommendedMinutes;
  final int cycleSecs;
  final DateTime? createdAt;
  final List<PatternStepModel> steps;
  final String slug;
  final String? description;

  const PatternModel({
    this.id = '',
    this.name = '',
    this.goalId = '',
    this.recommendedMinutes = 3,
    this.cycleSecs = 8,
    this.createdAt,
    this.steps = const [],
    this.slug = '',
    this.description,
  });

  PatternModel copyWith({
    String? id,
    String? name,
    String? goalId,
    int? recommendedMinutes,
    int? cycleSecs,
    DateTime? createdAt,
    List<PatternStepModel>? steps,
    String? slug,
    String? description,
  }) {
    return PatternModel(
      id: id ?? this.id,
      name: name ?? this.name,
      goalId: goalId ?? this.goalId,
      recommendedMinutes: recommendedMinutes ?? this.recommendedMinutes,
      cycleSecs: cycleSecs ?? this.cycleSecs,
      createdAt: createdAt ?? this.createdAt,
      steps: steps ?? this.steps,
      slug: slug ?? this.slug,
      description: description ?? this.description,
    );
  }

  factory PatternModel.fromJson(Map<String, dynamic> json) {
    return PatternModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      goalId: json['goal_id'] as String? ?? '',
      recommendedMinutes: json['recommended_minutes'] as int? ?? 3,
      cycleSecs: json['cycle_secs'] as int? ?? 8,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      steps: json['steps'] != null
          ? (json['steps'] as List)
              .map((step) =>
                  PatternStepModel.fromJson(step as Map<String, dynamic>))
              .toList()
          : [],
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'goal_id': goalId,
      'recommended_minutes': recommendedMinutes,
      'cycle_secs': cycleSecs,
      'created_at': createdAt?.toIso8601String(),
      'steps': steps.map((step) => step.toJson()).toList(),
      'slug': slug,
      'description': description,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PatternModel &&
        other.id == id &&
        other.name == name &&
        other.goalId == goalId &&
        other.recommendedMinutes == recommendedMinutes &&
        other.cycleSecs == cycleSecs &&
        other.slug == slug &&
        other.description == description &&
        listEquals(other.steps, steps);
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        goalId,
        recommendedMinutes,
        cycleSecs,
        slug,
        description,
        Object.hashAll(steps),
      );
}

// Goal model for breathing goals
class GoalModel {
  final String id;
  final String slug;
  final String displayName;
  final String? description;
  final DateTime? createdAt;
  final int sortOrder;

  const GoalModel({
    this.id = '',
    this.slug = '',
    this.displayName = '',
    this.description,
    this.createdAt,
    this.sortOrder = 999,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      sortOrder: json['sort_order'] as int? ?? 999,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'display_name': displayName,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'sort_order': sortOrder,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoalModel &&
        other.id == id &&
        other.slug == slug &&
        other.displayName == displayName &&
        other.description == description &&
        other.sortOrder == sortOrder;
  }

  @override
  int get hashCode => Object.hash(
        id,
        slug,
        displayName,
        description,
        sortOrder,
      );
}

// Plain class for expanded steps
class ExpandedStep {
  final int inhaleSecs;
  final String inhaleMethod;
  final int holdInSecs;
  final int exhaleSecs;
  final String exhaleMethod;
  final int holdOutSecs;
  final String? cueText;

  ExpandedStep({
    required this.inhaleSecs,
    required this.inhaleMethod,
    required this.holdInSecs,
    required this.exhaleSecs,
    required this.exhaleMethod,
    required this.holdOutSecs,
    this.cueText,
  });

  factory ExpandedStep.fromStep(StepModel step) {
    return ExpandedStep(
      inhaleSecs: step.inhaleSecs,
      inhaleMethod: step.inhaleMethod,
      holdInSecs: step.holdInSecs,
      exhaleSecs: step.exhaleSecs,
      exhaleMethod: step.exhaleMethod,
      holdOutSecs: step.holdOutSecs,
      cueText: step.cueText,
    );
  }

  int get totalDuration => inhaleSecs + holdInSecs + exhaleSecs + holdOutSecs;
}

// Enum for breathing phases
enum BreathPhase { inhale, holdIn, exhale, holdOut }
