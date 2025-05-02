import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panic_button_flutter/data/breath_repository.dart';
import 'package:panic_button_flutter/models/breath_models.dart';
import 'package:flutter/material.dart';

// Supabase client provider
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Breath repository provider
final breathRepositoryProvider = Provider<BreathRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return BreathRepository(supabase);
});

// Goals provider
final goalsProvider = FutureProvider<List<GoalModel>>((ref) async {
  final repository = ref.watch(breathRepositoryProvider);
  return repository.getGoals();
});

// Selected goal provider - ensure 'calming' as the default goal
final selectedGoalProvider = StateProvider<String>((ref) => 'calming');

// Patterns for selected goal provider
final patternsForGoalProvider = FutureProvider<List<PatternModel>>((ref) async {
  final repository = ref.watch(breathRepositoryProvider);
  final goalSlug = ref.watch(selectedGoalProvider);

  try {
    // Get all goals (reduce log spam)
    final goals = await ref.watch(goalsProvider.future);

    // Make sure we have goals
    if (goals.isEmpty) {
      return [];
    }

    // Find the selected goal or fallback to first goal
    final selectedGoal = goals.firstWhere(
      (goal) => goal.slug == goalSlug,
      orElse: () {
        return goals.first;
      },
    );

    // Get patterns for this goal
    final patterns = await repository.getPatternsByGoal(selectedGoal.id);

    // Only log patterns for debugging when we have them
    if (patterns.isNotEmpty) {
      debugPrint(
          '✅ Found ${patterns.length} patterns for goal ${selectedGoal.displayName}');
    } else {
      debugPrint(
          '⚠️ No patterns found for goal ${selectedGoal.displayName} (${selectedGoal.id})');
    }

    return patterns;
  } catch (e) {
    // More concise error logging
    debugPrint('❌ Error loading patterns: $e');
    return [];
  }
});

// Selected pattern provider with a proper default constructor
final selectedPatternProvider = StateProvider<PatternModel?>((ref) => null);

// Selected duration in minutes provider
final selectedDurationProvider = StateProvider<int>((ref) {
  final pattern = ref.watch(selectedPatternProvider);
  return pattern?.recommendedMinutes ?? 3; // Default to 3 minutes
});

// Expanded steps provider
final expandedStepsProvider = FutureProvider<List<ExpandedStep>>((ref) async {
  final repository = ref.watch(breathRepositoryProvider);
  final pattern = ref.watch(selectedPatternProvider);
  final duration = ref.watch(selectedDurationProvider);

  if (pattern == null) {
    return []; // Return empty list if no pattern selected
  }

  try {
    final steps =
        await repository.expandPattern(pattern.id, targetMinutes: duration);
    // Only log success for debugging
    if (steps.isNotEmpty) {
      debugPrint(
          '✅ Expanded ${steps.length} steps for pattern ${pattern.name}');
    }
    return steps;
  } catch (e) {
    // Simplified error logging
    debugPrint('❌ Error expanding pattern: $e');

    // Create a default fallback pattern
    final defaultStep = ExpandedStep(
      cueText: 'Respira',
      inhaleSecs: 4,
      exhaleSecs: 4,
      holdInSecs: 0,
      holdOutSecs: 0,
      inhaleMethod: 'nose',
      exhaleMethod: 'nose',
    );

    final stepCount = (duration * 60 / 8).ceil();
    return List.generate(stepCount, (_) => defaultStep);
  }
});

// Add a default pattern provider to initialize with a valid pattern
final defaultPatternProvider = FutureProvider<PatternModel?>((ref) async {
  try {
    // Only log once at beginning
    debugPrint('Attempting to get default pattern');

    final patterns = await ref.watch(patternsForGoalProvider.future);
    if (patterns.isNotEmpty) {
      debugPrint('✅ Found default pattern: ${patterns.first.name}');
      return patterns.first;
    }

    // Create a fallback pattern if none found
    return PatternModel(
      id: 'default',
      name: 'Respiración 4-4',
      goalId: 'default',
      recommendedMinutes: 3,
      cycleSecs: 8,
      steps: [],
    );
  } catch (e) {
    debugPrint('❌ Error getting default pattern: $e');

    // Return a minimal fallback pattern
    return PatternModel(
      id: 'default',
      name: 'Respiración 4-4',
      goalId: 'default',
      recommendedMinutes: 3,
      cycleSecs: 8,
      steps: [],
    );
  }
});
