import 'package:panic_button_flutter/models/breathing_exercise.dart';
import 'package:panic_button_flutter/models/breathwork_models.dart' as db;
import 'package:panic_button_flutter/services/breathwork_service.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExerciseService {
  final _breathworkService = BreathworkService();

  // ────────────────────────── Singleton
  static final ExerciseService _instance = ExerciseService._internal();
  factory ExerciseService() => _instance;
  ExerciseService._internal();

  /// Get the default exercise (4-6 Calming)
  Future<BreathingExercise?> getDefaultExercise() async {
    try {
      final routine = await _breathworkService.getDefaultRoutine();
      if (routine == null) return null;
      return getExerciseFromRoutine(routine.id);
    } catch (e) {
      print('Error getting default exercise: $e');
      return null;
    }
  }

  /// Get all breathing goals
  Future<List<db.Goal>> getGoals() async {
    try {
      return await _breathworkService.getGoals();
    } catch (e) {
      print('Error getting goals: $e');
      return [];
    }
  }

  /// Get all routines for a goal
  Future<List<db.Routine>> getRoutinesByGoal(String goalId) async {
    try {
      return await _breathworkService.getRoutinesByGoal(goalId);
    } catch (e) {
      print('Error getting routines: $e');
      return [];
    }
  }

  /// Convert a routine to a breathing exercise
  Future<BreathingExercise?> getExerciseFromRoutine(String routineId) async {
    try {
      // Get all items in the routine
      final items = await _breathworkService.getRoutineItems(routineId);
      if (items.isEmpty) return null;

      // Get the first pattern (for now we only support one pattern per routine)
      final firstItem = items.first;
      final pattern = firstItem['pattern'];
      if (pattern == null) return null;

      // Get all steps for this pattern
      final patternSteps =
          await _breathworkService.getPatternSteps(pattern['id']);
      if (patternSteps.isEmpty) return null;

      // Build the phases list
      final phases = <BreathingPhase>[];
      int totalSeconds = 0;

      for (final patternStep in patternSteps) {
        final step = patternStep['step'];
        final repetitions = (patternStep['repetitions'] ?? 1) as int;

        // For each repetition
        for (var i = 0; i < repetitions; i++) {
          // Add inhale phase
          if (step['inhale_secs'] > 0) {
            final inhaleSecs = (step['inhale_secs'] as num).toInt();
            phases.add(BreathingPhase(
              type: PhaseType.inhale,
              seconds: inhaleSecs,
              method: step['inhale_method'],
            ));
            totalSeconds += inhaleSecs;
          }

          // Add hold after inhale
          if (step['hold_in_secs'] > 0) {
            final holdInSecs = (step['hold_in_secs'] as num).toInt();
            phases.add(BreathingPhase(
              type: PhaseType.holdIn,
              seconds: holdInSecs,
            ));
            totalSeconds += holdInSecs;
          }

          // Add exhale phase
          if (step['exhale_secs'] > 0) {
            final exhaleSecs = (step['exhale_secs'] as num).toInt();
            phases.add(BreathingPhase(
              type: PhaseType.exhale,
              seconds: exhaleSecs,
              method: step['exhale_method'],
            ));
            totalSeconds += exhaleSecs;
          }

          // Add hold after exhale
          if (step['hold_out_secs'] > 0) {
            final holdOutSecs = (step['hold_out_secs'] as num).toInt();
            phases.add(BreathingPhase(
              type: PhaseType.holdOut,
              seconds: holdOutSecs,
            ));
            totalSeconds += holdOutSecs;
          }
        }
      }

      // Calculate total minutes (rounded up)
      final totalMinutes = (totalSeconds / 60).ceil();

      return BreathingExercise(
        id: routineId,
        name: pattern['name'] ?? 'Ejercicio sin nombre',
        description: pattern['description'],
        phases: phases,
        totalMinutes: totalMinutes,
      );
    } catch (e) {
      print('Error converting routine to exercise: $e');
      return null;
    }
  }

  /// Track that a routine was completed
  Future<void> trackRoutineCompletion(String routineId) async {
    try {
      await _breathworkService.updateRoutineStatus(routineId);
    } catch (e) {
      print('Error tracking routine completion: $e');
    }
  }
}
