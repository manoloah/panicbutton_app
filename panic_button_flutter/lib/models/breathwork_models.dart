/// Represents a breathing goal like "Calming" or "Energizing"
class Goal {
  final String id;
  final String slug;
  final String displayName;
  final String? description;

  Goal({
    required this.id,
    required this.slug,
    required this.displayName,
    this.description,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'],
      slug: json['slug'],
      displayName: json['display_name'],
      description: json['description'],
    );
  }
}

/// Represents a single breathing step with timing and method
class Step {
  final String id;
  final int inhaleSeconds;
  final String inhaleMethod; // 'nose', 'mouth'
  final int holdInSeconds;
  final int exhaleSeconds;
  final String exhaleMethod; // 'nose', 'mouth'
  final int holdOutSeconds;
  final String? cueText;

  Step({
    required this.id,
    required this.inhaleSeconds,
    required this.inhaleMethod,
    required this.holdInSeconds,
    required this.exhaleSeconds,
    required this.exhaleMethod,
    required this.holdOutSeconds,
    this.cueText,
  });

  factory Step.fromJson(Map<String, dynamic> json) {
    return Step(
      id: json['id'],
      inhaleSeconds: json['inhale_secs'],
      inhaleMethod: json['inhale_method'],
      holdInSeconds: json['hold_in_secs'],
      exhaleSeconds: json['exhale_secs'],
      exhaleMethod: json['exhale_method'],
      holdOutSeconds: json['hold_out_secs'],
      cueText: json['cue_text'],
    );
  }
}

/// Represents a named bundle of steps (e.g. "4-7-8 Breathing")
class Pattern {
  final String id;
  final String name;
  final String? description;
  final String? goalId;
  final String? createdBy;

  Pattern({
    required this.id,
    required this.name,
    this.description,
    this.goalId,
    this.createdBy,
  });

  factory Pattern.fromJson(Map<String, dynamic> json) {
    return Pattern(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      goalId: json['goal_id'],
      createdBy: json['created_by'],
    );
  }
}

/// Connects steps to a pattern with position and repetition information
class PatternStep {
  final String patternId;
  final String stepId;
  final int position;
  final int repetitions;

  PatternStep({
    required this.patternId,
    required this.stepId,
    required this.position,
    this.repetitions = 1,
  });

  factory PatternStep.fromJson(Map<String, dynamic> json) {
    return PatternStep(
      patternId: json['pattern_id'],
      stepId: json['step_id'],
      position: json['position'],
      repetitions: json['repetitions'] ?? 1,
    );
  }
}

/// Represents a complete breathing routine (playlist)
class Routine {
  final String id;
  final String? name;
  final String? goalId;
  final int? totalMinutes;
  final String? createdBy;
  final bool isPublic;

  Routine({
    required this.id,
    this.name,
    this.goalId,
    this.totalMinutes,
    this.createdBy,
    this.isPublic = true,
  });

  factory Routine.fromJson(Map<String, dynamic> json) {
    return Routine(
      id: json['id'],
      name: json['name'],
      goalId: json['goal_id'],
      totalMinutes: json['total_minutes'],
      createdBy: json['created_by'],
      isPublic: json['is_public'] ?? true,
    );
  }
}

/// Connects patterns or steps to a routine with position information
class RoutineItem {
  final String routineId;
  final int position;
  final String? patternId;
  final String? stepId;
  final int repetitions;

  RoutineItem({
    required this.routineId,
    required this.position,
    this.patternId,
    this.stepId,
    this.repetitions = 1,
  });

  factory RoutineItem.fromJson(Map<String, dynamic> json) {
    return RoutineItem(
      routineId: json['routine_id'],
      position: json['position'],
      patternId: json['pattern_id'],
      stepId: json['step_id'],
      repetitions: json['repetitions'] ?? 1,
    );
  }
}

/// Tracks user's history with specific routines
class UserRoutineStatus {
  final String userId;
  final String routineId;
  final DateTime? lastRun;
  final int totalRuns;

  UserRoutineStatus({
    required this.userId,
    required this.routineId,
    this.lastRun,
    this.totalRuns = 0,
  });

  factory UserRoutineStatus.fromJson(Map<String, dynamic> json) {
    return UserRoutineStatus(
      userId: json['user_id'],
      routineId: json['routine_id'],
      lastRun:
          json['last_run'] != null ? DateTime.parse(json['last_run']) : null,
      totalRuns: json['total_runs'] ?? 0,
    );
  }
}
