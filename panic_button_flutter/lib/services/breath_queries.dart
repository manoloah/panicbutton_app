import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panic_button_flutter/models/breath_types.dart';

/// The Supabase client instance
final supabase = Supabase.instance.client;

/// Default breathing patterns for each goal
final Map<String, ExpandedStep> _defaultPatterns = {
  'calming': const ExpandedStep(
    inhaleSecs: 4,
    inhaleMethod: 'nose',
    holdInSecs: 0,
    exhaleSecs: 8,
    exhaleMethod: 'nose',
    holdOutSecs: 0,
    repetitions: 1,
  ),
  'focusing': const ExpandedStep(
    inhaleSecs: 4,
    inhaleMethod: 'nose',
    holdInSecs: 0,
    exhaleSecs: 7,
    exhaleMethod: 'nose',
    holdOutSecs: 0,
    repetitions: 1,
  ),
  'energizing': const ExpandedStep(
    inhaleSecs: 6,
    inhaleMethod: 'nose',
    holdInSecs: 0,
    exhaleSecs: 2,
    exhaleMethod: 'nose',
    holdOutSecs: 0,
    repetitions: 1,
  ),
  'grounding': const ExpandedStep(
    inhaleSecs: 5,
    inhaleMethod: 'nose',
    holdInSecs: 0,
    exhaleSecs: 5,
    exhaleMethod: 'nose',
    holdOutSecs: 0,
    repetitions: 1,
  ),
  'kids': const ExpandedStep(
    inhaleSecs: 4,
    inhaleMethod: 'nose',
    holdInSecs: 0,
    exhaleSecs: 4,
    exhaleMethod: 'nose',
    holdOutSecs: 0,
    repetitions: 1,
  ),
};

/// Default routines for each goal
final Map<String, List<Routine>> _defaultRoutines = {
  'calming': [
    Routine(
      id: 'calm-1',
      name: 'Respiración 4-8',
      goalId: 'calming',
      totalMinutes: 5,
      isPublic: true,
    ),
  ],
  'focusing': [
    Routine(
      id: 'focus-1',
      name: 'Respiración 4-7',
      goalId: 'focusing',
      totalMinutes: 5,
      isPublic: true,
    ),
  ],
  'energizing': [
    Routine(
      id: 'energy-1',
      name: 'Respiración 6-2',
      goalId: 'energizing',
      totalMinutes: 4,
      isPublic: true,
    ),
  ],
  'grounding': [
    Routine(
      id: 'ground-1',
      name: 'Respiración 5-5',
      goalId: 'grounding',
      totalMinutes: 5,
      isPublic: true,
    ),
  ],
};

/// Retrieves a list of routines for a specific goal slug
Future<List<Routine>> getRoutinesForGoal(String goalSlug) async {
  try {
    // First, get the goal by slug
    final goalResponse = await supabase
        .from('goals')
        .select()
        .eq('slug', goalSlug)
        .maybeSingle();

    if (goalResponse == null) {
      // Goal not found, return default routines
      return _defaultRoutines[goalSlug] ?? [];
    }

    final goal = Goal.fromJson(goalResponse);

    // Get routines for this goal
    final routinesResponse = await supabase
        .from('routines')
        .select()
        .eq('goal_id', goal.id)
        .order('created_at', ascending: false);

    if (routinesResponse == null || routinesResponse.isEmpty) {
      // No routines found, return default routines
      return _defaultRoutines[goalSlug] ?? [];
    }

    return routinesResponse
        .map<Routine>((data) => Routine.fromJson(data))
        .toList();
  } catch (e) {
    debugPrint('Error fetching routines for goal: $e');
    // Return default routines if error occurs
    return _defaultRoutines[goalSlug] ?? [];
  }
}

/// Retrieves a list of expanded breathwork steps for a specific goal slug
///
/// This fetches a complete routine with all steps expanded and ordered,
/// ready to be used for animation in the breathwork screen
Future<List<ExpandedStep>> getRoutinesByGoalSlug(String slug) async {
  try {
    // First, get the goal by slug
    final goalResponse =
        await supabase.from('goals').select().eq('slug', slug).maybeSingle();

    if (goalResponse == null) {
      // Goal not found, return default pattern for this goal
      return _getDefaultPattern(slug);
    }

    final goal = Goal.fromJson(goalResponse);

    // Get a routine for this goal
    final routineResponse = await supabase
        .from('routines')
        .select(
            '*, routine_items!inner(position, repetitions, pattern_id, step_id)')
        .eq('goal_id', goal.id)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (routineResponse == null) {
      // No routine found, return default pattern for this goal
      return _getDefaultPattern(slug);
    }

    final routine = Routine.fromJson(routineResponse);

    // Expanded steps to return
    final List<ExpandedStep> expandedSteps = [];

    // Process each routine item
    if (routine.items != null && routine.items!.isNotEmpty) {
      for (final item in routine.items!) {
        if (item.stepId != null) {
          // Direct step reference - ensure stepId is not null
          final String stepId = item.stepId!;
          final stepResponse = await supabase
              .from('steps')
              .select()
              .eq('id', stepId)
              .maybeSingle();

          if (stepResponse == null) continue;

          final step = Step.fromJson(stepResponse);

          expandedSteps.add(
            ExpandedStep(
              inhaleSecs: step.inhaleSecs,
              inhaleMethod: step.inhaleMethod,
              holdInSecs: step.holdInSecs,
              exhaleSecs: step.exhaleSecs,
              exhaleMethod: step.exhaleMethod,
              holdOutSecs: step.holdOutSecs,
              cueText: step.cueText,
              repetitions: item.repetitions,
            ),
          );
        } else if (item.patternId != null) {
          // Pattern reference - ensure patternId is not null
          final String patternId = item.patternId!;
          // Need to get all steps in this pattern
          final patternStepsResponse = await supabase
              .from('pattern_steps')
              .select('*, step:steps(*)')
              .eq('pattern_id', patternId)
              .order('position', ascending: true);

          for (final patternStepData in patternStepsResponse) {
            final patternStep = PatternStep.fromJson(patternStepData);

            if (patternStep.step != null) {
              expandedSteps.add(
                ExpandedStep(
                  inhaleSecs: patternStep.step!.inhaleSecs,
                  inhaleMethod: patternStep.step!.inhaleMethod,
                  holdInSecs: patternStep.step!.holdInSecs,
                  exhaleSecs: patternStep.step!.exhaleSecs,
                  exhaleMethod: patternStep.step!.exhaleMethod,
                  holdOutSecs: patternStep.step!.holdOutSecs,
                  cueText: patternStep.step!.cueText,
                  repetitions: patternStep.repetitions,
                ),
              );
            }
          }
        }
      }
    }

    if (expandedSteps.isEmpty) {
      // No steps found in the routine, return default pattern
      return _getDefaultPattern(slug);
    }

    return expandedSteps;
  } catch (e) {
    debugPrint('Error fetching breathing routine: $e');
    // Return a default step if we can't get the routine
    return _getDefaultPattern(slug);
  }
}

/// Gets the default pattern for a given goal
List<ExpandedStep> _getDefaultPattern(String slug) {
  // Return the default pattern for this goal, or resonance breathing if not found
  return [_defaultPatterns[slug] ?? _defaultPatterns['calming']!];
}

/// Logs a routine run for the user
///
/// Increments total_runs and updates last_run timestamp
Future<void> logRoutineRun(String userId, String routineId) async {
  try {
    await supabase.from('user_routine_status').upsert({
      'user_id': userId,
      'routine_id': routineId,
      'last_run': DateTime.now().toIso8601String(),
      'total_runs': supabase.rpc('increment_total_runs', params: {
        'p_user_id': userId,
        'p_routine_id': routineId,
      }),
    });
  } catch (e) {
    debugPrint('Error logging routine run: $e');
  }
}
