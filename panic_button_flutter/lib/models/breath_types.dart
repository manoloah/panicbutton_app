// Simplified data models for breathwork features
class Goal {
  final String id;
  final String slug;
  final String displayName;
  final String? description;

  const Goal({
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'display_name': displayName,
      'description': description,
    };
  }
}

class Step {
  final String id;
  final int inhaleSecs;
  final String inhaleMethod;
  final int holdInSecs;
  final int exhaleSecs;
  final String exhaleMethod;
  final int holdOutSecs;
  final String? cueText;
  final String? createdAt;

  const Step({
    required this.id,
    required this.inhaleSecs,
    required this.inhaleMethod,
    required this.holdInSecs,
    required this.exhaleSecs,
    required this.exhaleMethod,
    required this.holdOutSecs,
    this.cueText,
    this.createdAt,
  });

  factory Step.fromJson(Map<String, dynamic> json) {
    return Step(
      id: json['id'],
      inhaleSecs: json['inhale_secs'],
      inhaleMethod: json['inhale_method'],
      holdInSecs: json['hold_in_secs'],
      exhaleSecs: json['exhale_secs'],
      exhaleMethod: json['exhale_method'],
      holdOutSecs: json['hold_out_secs'],
      cueText: json['cue_text'],
      createdAt: json['created_at'],
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
      'created_at': createdAt,
    };
  }
}

class PatternStep {
  final String patternId;
  final String stepId;
  final int position;
  final int repetitions;
  final Step? step;

  const PatternStep({
    required this.patternId,
    required this.stepId,
    required this.position,
    required this.repetitions,
    this.step,
  });

  factory PatternStep.fromJson(Map<String, dynamic> json) {
    return PatternStep(
      patternId: json['pattern_id'],
      stepId: json['step_id'],
      position: json['position'],
      repetitions: json['repetitions'],
      step: json['step'] != null ? Step.fromJson(json['step']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pattern_id': patternId,
      'step_id': stepId,
      'position': position,
      'repetitions': repetitions,
      'step': step?.toJson(),
    };
  }
}

class Pattern {
  final String id;
  final String name;
  final String? description;
  final String? goalId;
  final String? createdBy;
  final String? createdAt;
  final List<PatternStep>? steps;

  const Pattern({
    required this.id,
    required this.name,
    this.description,
    this.goalId,
    this.createdBy,
    this.createdAt,
    this.steps,
  });

  factory Pattern.fromJson(Map<String, dynamic> json) {
    return Pattern(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      goalId: json['goal_id'],
      createdBy: json['created_by'],
      createdAt: json['created_at'],
      steps: json['steps'] != null
          ? List<PatternStep>.from(
              json['steps'].map((x) => PatternStep.fromJson(x)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'goal_id': goalId,
      'created_by': createdBy,
      'created_at': createdAt,
      'steps': steps?.map((x) => x.toJson()).toList(),
    };
  }
}

class RoutineItem {
  final String routineId;
  final int position;
  final String? patternId;
  final String? stepId;
  final int repetitions;
  final Pattern? pattern;
  final Step? step;

  const RoutineItem({
    required this.routineId,
    required this.position,
    this.patternId,
    this.stepId,
    this.repetitions = 1,
    this.pattern,
    this.step,
  });

  factory RoutineItem.fromJson(Map<String, dynamic> json) {
    return RoutineItem(
      routineId: json['routine_id'],
      position: json['position'],
      patternId: json['pattern_id'],
      stepId: json['step_id'],
      repetitions: json['repetitions'] ?? 1,
      pattern:
          json['pattern'] != null ? Pattern.fromJson(json['pattern']) : null,
      step: json['step'] != null ? Step.fromJson(json['step']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'routine_id': routineId,
      'position': position,
      'pattern_id': patternId,
      'step_id': stepId,
      'repetitions': repetitions,
      'pattern': pattern?.toJson(),
      'step': step?.toJson(),
    };
  }
}

class Routine {
  final String id;
  final String? name;
  final String? goalId;
  final int? totalMinutes;
  final String? createdBy;
  final bool isPublic;
  final String? createdAt;
  final List<RoutineItem>? items;

  const Routine({
    required this.id,
    this.name,
    this.goalId,
    this.totalMinutes,
    this.createdBy,
    this.isPublic = true,
    this.createdAt,
    this.items,
  });

  factory Routine.fromJson(Map<String, dynamic> json) {
    return Routine(
      id: json['id'],
      name: json['name'],
      goalId: json['goal_id'],
      totalMinutes: json['total_minutes'],
      createdBy: json['created_by'],
      isPublic: json['is_public'] ?? true,
      createdAt: json['created_at'],
      items: json['items'] != null
          ? List<RoutineItem>.from(
              json['items'].map((x) => RoutineItem.fromJson(x)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'goal_id': goalId,
      'total_minutes': totalMinutes,
      'created_by': createdBy,
      'is_public': isPublic,
      'created_at': createdAt,
      'items': items?.map((x) => x.toJson()).toList(),
    };
  }
}

class UserRoutineStatus {
  final String userId;
  final String routineId;
  final String? lastRun;
  final int totalRuns;

  const UserRoutineStatus({
    required this.userId,
    required this.routineId,
    this.lastRun,
    this.totalRuns = 0,
  });

  factory UserRoutineStatus.fromJson(Map<String, dynamic> json) {
    return UserRoutineStatus(
      userId: json['user_id'],
      routineId: json['routine_id'],
      lastRun: json['last_run'],
      totalRuns: json['total_runs'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'routine_id': routineId,
      'last_run': lastRun,
      'total_runs': totalRuns,
    };
  }
}

class ExpandedStep {
  final int inhaleSecs;
  final String inhaleMethod;
  final int holdInSecs;
  final int exhaleSecs;
  final String exhaleMethod;
  final int holdOutSecs;
  final String? cueText;
  final int repetitions;

  const ExpandedStep({
    required this.inhaleSecs,
    required this.inhaleMethod,
    required this.holdInSecs,
    required this.exhaleSecs,
    required this.exhaleMethod,
    required this.holdOutSecs,
    this.cueText,
    required this.repetitions,
  });
}
