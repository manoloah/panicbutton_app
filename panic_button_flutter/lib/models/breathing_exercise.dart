import 'package:panic_button_flutter/models/breathwork_models.dart' as db;

/// A class that represents a runnable breathing exercise for the UI
class BreathingExercise {
  final String id;
  final String name;
  final String? description;
  final String? goalId;
  final String? goalName;
  final List<BreathingPhase> phases;
  final int totalMinutes;

  BreathingExercise({
    required this.id,
    required this.name,
    this.description,
    this.goalId,
    this.goalName,
    required this.phases,
    required this.totalMinutes,
  });

  factory BreathingExercise.fromStep(
    db.Step step, {
    required String id,
    String? name,
    int repetitions = 1,
  }) {
    final phases = <BreathingPhase>[];

    // Add inhale phase if not zero
    if (step.inhaleSeconds > 0) {
      phases.add(BreathingPhase(
        type: PhaseType.inhale,
        seconds: step.inhaleSeconds,
        method: step.inhaleMethod,
      ));
    }

    // Add hold after inhale if not zero
    if (step.holdInSeconds > 0) {
      phases.add(BreathingPhase(
        type: PhaseType.holdIn,
        seconds: step.holdInSeconds,
      ));
    }

    // Add exhale phase if not zero
    if (step.exhaleSeconds > 0) {
      phases.add(BreathingPhase(
        type: PhaseType.exhale,
        seconds: step.exhaleSeconds,
        method: step.exhaleMethod,
      ));
    }

    // Add hold after exhale if not zero
    if (step.holdOutSeconds > 0) {
      phases.add(BreathingPhase(
        type: PhaseType.holdOut,
        seconds: step.holdOutSeconds,
      ));
    }

    // Calculate total time in minutes (rounded up)
    final totalSeconds =
        phases.fold<int>(0, (sum, phase) => sum + phase.seconds) * repetitions;
    final totalMinutes = (totalSeconds / 60).ceil();

    return BreathingExercise(
      id: id,
      name: name ?? step.cueText ?? 'Ejercicio de respiración',
      phases: phases,
      totalMinutes: totalMinutes,
    );
  }

  /// Calculate a 4-digit code for the breathing exercise
  /// e.g. "4-7-8" for a 4s inhale, 7s hold, 8s exhale pattern
  String get patternCode {
    final phaseMap = <PhaseType, int>{};

    for (final phase in phases) {
      phaseMap[phase.type] = phase.seconds;
    }

    final inhale = phaseMap[PhaseType.inhale] ?? 0;
    final holdIn = phaseMap[PhaseType.holdIn] ?? 0;
    final exhale = phaseMap[PhaseType.exhale] ?? 0;
    final holdOut = phaseMap[PhaseType.holdOut] ?? 0;

    final parts = <String>[];
    if (inhale > 0) parts.add('$inhale');
    if (holdIn > 0) parts.add('$holdIn');
    if (exhale > 0) parts.add('$exhale');
    if (holdOut > 0) parts.add('$holdOut');

    return parts.join('-');
  }
}

enum PhaseType {
  inhale,
  holdIn,
  exhale,
  holdOut,
}

class BreathingPhase {
  final PhaseType type;
  final int seconds;
  final String? method; // 'nose' or 'mouth'

  const BreathingPhase({
    required this.type,
    required this.seconds,
    this.method,
  });

  String get displayName {
    switch (type) {
      case PhaseType.inhale:
        return 'Inhala';
      case PhaseType.holdIn:
        return 'Mantén';
      case PhaseType.exhale:
        return 'Exhala';
      case PhaseType.holdOut:
        return 'Relaja';
    }
  }
}
