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

class SelectedPatternNotifier extends StateNotifier<PatternModel?> {
  final Ref ref;
  SelectedPatternNotifier(this.ref) : super(null);

  // Set pattern directly (for compatibility) - with validation
  @override
  set state(PatternModel? pattern) {
    // Validate pattern before setting
    if (pattern != null) {
      // Check if pattern has invalid ID
      if (pattern.id == 'default' || pattern.id.isEmpty) {
        debugPrint(
            '⚠️ REJECTED invalid pattern with ID: "${pattern.id}", Name: "${pattern.name}"');
        return; // Don't set invalid patterns
      }

      // Check if pattern has valid UUID format
      bool isValidUUID = RegExp(
              r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
          .hasMatch(pattern.id);
      if (!isValidUUID) {
        debugPrint(
            '⚠️ REJECTED pattern with invalid UUID format: "${pattern.id}", Name: "${pattern.name}"');
        return; // Don't set patterns with invalid UUIDs
      }

      debugPrint(
          '✅ ACCEPTED valid pattern: ID="${pattern.id}", Name="${pattern.name}"');
    }

    super.state = pattern;
  }

  // Select a pattern by slug
  Future<void> selectPatternBySlug(String slug) async {
    try {
      // First, try to get all patterns for the current goal
      final patternsAsync = ref.read(patternsForGoalProvider);
      List<PatternModel> patterns = [];

      if (patternsAsync is AsyncData<List<PatternModel>>) {
        patterns = patternsAsync.value;
      } else {
        // If patterns are still loading, wait for them
        patterns = await ref.read(patternsForGoalProvider.future);
      }

      // Look for the pattern with matching slug
      PatternModel? matchingPattern;
      for (final pattern in patterns) {
        if (pattern.id == slug || pattern.slug == slug) {
          matchingPattern = pattern;
          break;
        }
      }

      // If we found a match, set it
      if (matchingPattern != null && matchingPattern.id.isNotEmpty) {
        super.state = matchingPattern;
        debugPrint('✅ Successfully selected pattern by slug: $slug');
        return;
      }

      // If we didn't find a match through the goal patterns, we need to query directly
      final repository = ref.read(breathRepositoryProvider);
      final patternFromSlug = await repository.getPatternBySlug(slug);

      if (patternFromSlug != null) {
        super.state = patternFromSlug;
        debugPrint('✅ Successfully fetched pattern directly by slug: $slug');
        return;
      }

      debugPrint('⚠️ Could not find pattern with slug: $slug');
    } catch (e) {
      debugPrint('❌ Error selecting pattern by slug: $e');
    }
  }
}

final selectedPatternProvider =
    StateNotifierProvider<SelectedPatternNotifier, PatternModel?>((ref) {
  return SelectedPatternNotifier(ref);
});

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
    // First try to get the coherent_4_6 pattern directly
    final repository = ref.watch(breathRepositoryProvider);
    final coherentPattern = await repository.getPatternBySlug('coherent_4_6');

    if (coherentPattern != null) {
      debugPrint('✅ Found coherent_4_6 pattern as default');
      return coherentPattern;
    }

    // If coherent_4_6 not found, fall back to the first pattern from 'calming' goal
    debugPrint(
        '⚠️ coherent_4_6 pattern not found, falling back to first pattern');

    // Set selected goal to 'calming'
    ref.read(selectedGoalProvider.notifier).state = 'calming';

    // Get patterns for calming goal
    final patterns = await ref.watch(patternsForGoalProvider.future);
    if (patterns.isNotEmpty) {
      debugPrint('✅ Found fallback default pattern: ${patterns.first.name}');
      return patterns.first;
    }

    // Create a fallback pattern if none found
    // Return null instead of creating invalid UUID pattern
    debugPrint('⚠️ No patterns found, returning null for default pattern');
    return null;
  } catch (e) {
    debugPrint('❌ Error getting default pattern: $e');

    // Return null instead of creating invalid UUID pattern
    return null;
  }
});
